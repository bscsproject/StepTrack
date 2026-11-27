import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:step_track/controller/auth_controller.dart';
import 'package:step_track/services/auth_service.dart';
import 'package:step_track/views/home/create_challenge_screen.dart';
import 'package:step_track/views/home/create_group_screen.dart';
import 'package:step_track/views/home/invite_friend_helper.dart';
import 'package:step_track/views/home/track_calories_screen.dart';
import 'package:step_track/views/home/weight_loss_plan_screen.dart';
import 'package:step_track/views/home/weight_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  final Widget? discoverScreen;
  final Widget? chatsScreen;
  final Widget? insightsScreen;

  const HomeScreen({
    super.key,
    this.discoverScreen,
    this.chatsScreen,
    this.insightsScreen,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _authBoxName = 'steptrack_auth_box';
  static const String _stepsCacheKeyPrefix = 'steps_by_day_';
  static const String _sensorCountCacheKeyPrefix = 'sensor_step_count_';
  static const String _stepSyncPendingKeyPrefix = 'step_sync_pending_';
  static const String _activeGroupCacheKey = 'active_group_id';
  static const Duration _stepSyncDelay = Duration(seconds: 15);

  static const String _calAppPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.google.android.apps.fitness';

  int _navIndex = 0;
  int _rangeIndex = 0;
  bool _isQuickMenuOpen = false;
  bool _showNewPublicGroupBanner = true;
  DateTime _selectedDate = DateTime.now();

  String _userName = '';
  String _userInitial = '';
  Color _avatarColor = const Color(0xFF7C4DFF);
  int _stepsGoal = 0;
  double? _weightKg;
  double? _heightCm;
  int _streakDays = 0;
  List<String> _invitedFriends = const [];
  List<StepTrackGroupModel> _groups = const [];
  List<StepTrackChallengeModel> _challenges = const [];
  String? _activeGroupId;

  final Map<String, int> _stepsByDay = <String, int>{};
  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _userDocumentSubscription;
  Timer? _stepSyncTimer;
  int? _lastSensorStepCount;
  bool _stepTrackingNoticeShown = false;
  bool _isStartingStepTracking = false;
  bool _stepsNeedSync = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreLocalStepState();
    _syncFromSavedUserData();
    _startUserDocumentSync();
    unawaited(_startStepTracking());
    if (_stepsNeedSync) {
      _scheduleStepSync();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stepSubscription?.cancel();
    _userDocumentSubscription?.cancel();
    _stepSyncTimer?.cancel();
    unawaited(_flushStepDataSync());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _syncFromSavedUserData();
      unawaited(_startStepTracking());
      if (_stepsNeedSync) {
        _scheduleStepSync();
      }
    }
  }

  String get _stepStorageUserId =>
      _authService.currentUser?.uid ??
      _authService.getCachedUser()?.uid ??
      'guest_user';

  String get _stepsCacheKey => '$_stepsCacheKeyPrefix$_stepStorageUserId';
  String get _sensorCountCacheKey =>
      '$_sensorCountCacheKeyPrefix$_stepStorageUserId';
  String get _stepSyncPendingKey =>
      '$_stepSyncPendingKeyPrefix$_stepStorageUserId';

  Map<String, int> _parseStepMap(Object? raw) {
    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (error) {
        debugPrint('Could not decode saved step totals: $error');
        return <String, int>{};
      }
    }

    if (raw is! Map) return <String, int>{};

    final parsed = <String, int>{};
    for (final entry in raw.entries) {
      final dateKey = entry.key.toString();
      final value = entry.value;
      final steps = value is num
          ? value.toInt()
          : int.tryParse(value.toString());
      if (dateKey.isNotEmpty && steps != null && steps >= 0) {
        parsed[dateKey] = steps;
      }
    }
    return parsed;
  }

  void _restoreLocalStepState() {
    if (!Hive.isBoxOpen(_authBoxName)) {
      debugPrint(
        'StepTrack auth box is not open; step cache cannot be loaded.',
      );
      return;
    }

    final box = Hive.box(_authBoxName);
    _stepsByDay.addAll(_parseStepMap(box.get(_stepsCacheKey)));
    _stepsNeedSync = box.get(_stepSyncPendingKey) == true;
    _activeGroupId = box.get(_activeGroupCacheKey)?.toString();
    final savedSensorCount = int.tryParse(
      box.get(_sensorCountCacheKey)?.toString() ?? '',
    );
    if (savedSensorCount != null && savedSensorCount >= 0) {
      _lastSensorStepCount = savedSensorCount;
    }
  }

  Future<void> _persistLocalStepState() async {
    if (!Hive.isBoxOpen(_authBoxName)) {
      throw StateError('Hive box "$_authBoxName" is not open.');
    }

    final box = Hive.box(_authBoxName);
    await box.put(_stepsCacheKey, Map<String, int>.from(_stepsByDay));
    await box.put(_stepSyncPendingKey, _stepsNeedSync);
    if (_lastSensorStepCount != null) {
      await box.put(_sensorCountCacheKey, _lastSensorStepCount);
    }
  }

  void _startUserDocumentSync() {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    _userDocumentSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (snapshot) => unawaited(_applyRemoteUserData(snapshot)),
          onError: (Object error) {
            debugPrint('HomeScreen Firestore listener failed: $error');
            _showStepTrackingNotice(
              'Sync unavailable',
              'Could not receive live account updates. Your locally saved steps are still available.',
            );
          },
        );
  }

  Future<void> _applyRemoteUserData(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    if (!mounted) return;
    final data = snapshot.data();
    if (data == null) return;

    final remoteSteps = _parseStepMap(data['stepsByDay']);
    var stepsChanged = false;
    for (final entry in remoteSteps.entries) {
      final local = _stepsByDay[entry.key] ?? 0;
      if (entry.value > local) {
        _stepsByDay[entry.key] = entry.value;
        stepsChanged = true;
      } else if (local > entry.value) {
        _stepsNeedSync = true;
      }
    }
    for (final entry in _stepsByDay.entries) {
      if (entry.value > (remoteSteps[entry.key] ?? 0)) {
        _stepsNeedSync = true;
      }
    }

    if (Hive.isBoxOpen(_authBoxName)) {
      final box = Hive.box(_authBoxName);
      final remoteGroups = data['groups'];
      if (remoteGroups is List) {
        await box.put(
          CreateGroupScreen.groupsKey,
          jsonEncode(remoteGroups.whereType<Map>().toList()),
        );
      }
      final remoteChallenges = data['challenges'];
      if (remoteChallenges is List) {
        await box.put(
          ChallengeStorageHelper.challengesKey,
          jsonEncode(remoteChallenges.whereType<Map>().toList()),
        );
      }
    }

    if (!mounted) return;
    if (data['activeGroupId'] is String) {
      _activeGroupId = data['activeGroupId'] as String;
    }
    _syncFromSavedUserData();

    if (stepsChanged || _stepsNeedSync) {
      unawaited(
        _persistLocalStepState().catchError((Object error) {
          debugPrint('Could not cache Firestore step totals: $error');
        }),
      );
      _updateChallengeProgress();
    }
    if (_stepsNeedSync) {
      _scheduleStepSync();
    }
  }

  Future<void> _startStepTracking() async {
    if (_isStartingStepTracking) return;
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      _showStepTrackingNotice(
        'Step sensor unavailable',
        'Live step counting requires an Android or iOS device with a pedometer sensor.',
      );
      return;
    }

    _isStartingStepTracking = true;
    try {
      await _stepSubscription?.cancel();
      _stepSubscription = null;

      final permission = defaultTargetPlatform == TargetPlatform.android
          ? Permission.activityRecognition
          : Permission.sensors;
      final permissionStatus = await permission.status;
      if (!permissionStatus.isGranted && !permissionStatus.isLimited) {
        _showStepTrackingNotice(
          'Activity permission needed',
          'Allow Motion Sensor permission to track your steps.',
          showSettings: true,
        );
        return;
      }

      _stepSubscription = Pedometer.stepCountStream.listen(
        _recordSensorSteps,
        onError: _handleStepSensorError,
      );
      _stepTrackingNoticeShown = false;
    } catch (error, stackTrace) {
      debugPrint('Could not start the pedometer stream: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showStepTrackingNotice(
        'Step sensor unavailable',
        'The device step sensor could not be started.',
      );
    } finally {
      _isStartingStepTracking = false;
    }
  }

  void _handleStepSensorError(Object error) {
    debugPrint('Pedometer stream failed: $error');
    _showStepTrackingNotice(
      'Step sensor unavailable',
      'This device could not provide step data. Check its sensor and permissions.',
    );
  }

  void _recordSensorSteps(StepCount event) {
    if (!mounted || event.steps < 0) return;

    final previousCount = _lastSensorStepCount;
    final delta = previousCount == null
        ? event.steps
        : event.steps >= previousCount
        ? event.steps - previousCount
        : event.steps;
    _lastSensorStepCount = event.steps;

    if (delta <= 0) {
      unawaited(
        _persistLocalStepState().catchError((Object error) {
          debugPrint('Could not cache pedometer state: $error');
        }),
      );
      return;
    }

    final dateKey = _dateKey(event.timeStamp.toLocal());
    _stepsByDay.update(
      dateKey,
      (steps) => steps + delta,
      ifAbsent: () => delta,
    );
    _stepsNeedSync = true;

    setState(() => _streakDays = _calculateStreakDays());
    _updateChallengeProgress();
    unawaited(
      _persistLocalStepState().catchError((Object error) {
        debugPrint('Could not persist step data locally: $error');
        if (mounted) {
          _showStepTrackingNotice(
            'Step storage unavailable',
            'Step totals could not be saved to this device.',
          );
        }
      }),
    );
    _scheduleStepSync();
  }

  int _calculateStreakDays() {
    if (_stepsGoal <= 0) return 0;

    var streak = 0;
    var day = DateTime.now();
    while ((_stepsByDay[_dateKey(day)] ?? 0) >= _stepsGoal) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  void _updateChallengeProgress() {
    var changed = false;
    final updatedChallenges = _challenges.map((challenge) {
      final completedDays = <int>[];
      final startDate = DateTime(
        challenge.startDate.year,
        challenge.startDate.month,
        challenge.startDate.day,
      );
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      for (var index = 0; index < challenge.durationDays; index++) {
        final challengeDay = startDate.add(Duration(days: index));
        if (challengeDay.isAfter(todayDate)) break;
        if ((_stepsByDay[_dateKey(challengeDay)] ?? 0) >=
            challenge.dailyGoalSteps) {
          completedDays.add(index);
        }
      }

      final sameDays =
          completedDays.length == challenge.completedDayIndices.length &&
          completedDays.every(challenge.completedDayIndices.contains);
      if (sameDays) return challenge;

      changed = true;
      return challenge.copyWith(completedDayIndices: completedDays);
    }).toList();

    if (!changed) return;
    setState(() => _challenges = updatedChallenges);
    unawaited(
      ChallengeStorageHelper.saveChallenges(
        updatedChallenges,
        uid: _authService.currentUser?.uid,
      ).catchError((Object error) {
        debugPrint('Could not save challenge step progress: $error');
      }),
    );
  }

  void _scheduleStepSync() {
    if (_stepSyncTimer != null || !_stepsNeedSync) return;
    _stepSyncTimer = Timer(_stepSyncDelay, () {
      _stepSyncTimer = null;
      unawaited(_flushStepDataSync());
    });
  }

  Future<void> _flushStepDataSync() async {
    final uid = _authService.currentUser?.uid;
    if (!_stepsNeedSync || uid == null) return;

    final localTotals = Map<String, int>.from(_stepsByDay);
    var syncedTotals = <String, int>{};
    try {
      final userDocument = _firestore.collection('users').doc(uid);
      await _firestore.runTransaction<void>((transaction) async {
        final snapshot = await transaction.get(userDocument);
        final remoteTotals = _parseStepMap(snapshot.data()?['stepsByDay']);
        for (final entry in localTotals.entries) {
          final remoteValue = remoteTotals[entry.key] ?? 0;
          if (entry.value > remoteValue) {
            remoteTotals[entry.key] = entry.value;
          }
        }
        syncedTotals = remoteTotals;
        transaction.set(userDocument, {
          'stepsByDay': remoteTotals,
          'stepsUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
      for (final entry in syncedTotals.entries) {
        _stepsByDay.update(
          entry.key,
          (steps) => math.max(steps, entry.value),
          ifAbsent: () => entry.value,
        );
      }
      _stepsNeedSync = _stepsByDay.entries.any(
        (entry) => entry.value > (syncedTotals[entry.key] ?? 0),
      );
      await _persistLocalStepState();
      if (_stepsNeedSync && mounted) {
        _scheduleStepSync();
      }
    } catch (error, stackTrace) {
      _stepsNeedSync = true;
      debugPrint('Could not sync steps to Firestore: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _persistLocalStepState().catchError((Object cacheError) {
        debugPrint('Could not cache pending steps: $cacheError');
      });
      if (mounted) {
        _showStepTrackingNotice(
          'Step sync delayed',
          'Steps are saved locally and will sync when your connection is available.',
        );
        _scheduleStepSync();
      }
    }
  }

  void _showStepTrackingNotice(
    String title,
    String message, {
    bool showSettings = false,
  }) {
    if (_stepTrackingNoticeShown || !mounted) return;
    _stepTrackingNoticeShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Get.snackbar(
        title,
        message,
        backgroundColor: const Color(0xFF15222B),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        mainButton: showSettings
            ? TextButton(
                onPressed: () => openAppSettings(),
                child: const Text(
                  'Settings',
                  style: TextStyle(color: Color(0xFF4FD0F8)),
                ),
              )
            : null,
      );
    });
  }

  String _dateKey(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  String _displayDate(DateTime d) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dd = d.day.toString().padLeft(2, '0');
    return '$dd-${months[d.month - 1]}-${d.year}';
  }

  void _syncFromSavedUserData() {
    final cachedUser = _authService.getCachedUser();
    final metrics = _authService.getCachedSetupMetrics();
    final goalRaw = _authService.getCachedMainGoal();
    final invites = _authService.getCachedInvitedFriends();
    final loadedGroups = CreateGroupScreen.loadCachedGroups();
    final loadedChallenges = ChallengeStorageHelper.loadChallenges();
    final cachedSteps = Hive.isBoxOpen(_authBoxName)
        ? _parseStepMap(Hive.box(_authBoxName).get(_stepsCacheKey))
        : <String, int>{};
    for (final entry in cachedSteps.entries) {
      _stepsByDay.update(
        entry.key,
        (steps) => math.max(steps, entry.value),
        ifAbsent: () => entry.value,
      );
    }

    final rawName = (cachedUser?.name ?? '').trim();
    final resolvedName = rawName.isNotEmpty ? rawName : 'User';

    int parsedGoal = 0;
    if (goalRaw != null && goalRaw.isNotEmpty) {
      final digitsOnly = goalRaw.replaceAll(RegExp(r'[^0-9]'), '');
      final asInt = int.tryParse(digitsOnly);
      if (asInt != null && asInt > 0) {
        parsedGoal = asInt;
      }
    }

    double? parsedWeight;
    if (metrics?['weightKg'] != null) {
      parsedWeight = double.tryParse(metrics!['weightKg'].toString());
    }

    double? parsedHeight;
    if (metrics?['heightCm'] != null) {
      parsedHeight = double.tryParse(metrics!['heightCm'].toString());
    }

    int calculatedStreak = 0;
    if (parsedGoal > 0) {
      DateTime cursor = DateTime.now();
      while ((_stepsByDay[_dateKey(cursor)] ?? 0) >= parsedGoal) {
        calculatedStreak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }

    String? selectedGroupId = _activeGroupId;
    if (selectedGroupId == null && Hive.isBoxOpen(_authBoxName)) {
      selectedGroupId =
          Hive.box(_authBoxName).get(_activeGroupCacheKey)?.toString();
    }
    if (loadedGroups.isNotEmpty) {
      final exists = loadedGroups.any((g) => g.id == selectedGroupId);
      if (!exists) {
        selectedGroupId = loadedGroups.last.id;
      }
    } else {
      selectedGroupId = null;
    }

    setState(() {
      _userName = resolvedName;
      _userInitial = resolvedName[0].toUpperCase();
      _avatarColor = cachedUser?.avatarColorValue != null
          ? Color(cachedUser!.avatarColorValue!)
          : const Color(0xFF7C4DFF);
      _stepsGoal = parsedGoal;
      _weightKg = parsedWeight;
      _heightCm = parsedHeight;
      _invitedFriends = invites;
      _groups = loadedGroups;
      _challenges = loadedChallenges;
      _activeGroupId = selectedGroupId;
      _streakDays = calculatedStreak;
    });
    _updateChallengeProgress();
  }

  Future<void> _selectActiveGroup(String groupId) async {
    setState(() => _activeGroupId = groupId);
    try {
      if (!Hive.isBoxOpen(_authBoxName)) {
        throw StateError('Hive box "$_authBoxName" is not open.');
      }
      await Hive.box(_authBoxName).put(_activeGroupCacheKey, groupId);

      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set({
          'activeGroupId': groupId,
        }, SetOptions(merge: true));
      }
    } catch (error, stackTrace) {
      debugPrint('Could not save the selected group: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        Get.snackbar(
          'Group selection not saved',
          'Could not save your selected group.',
          backgroundColor: const Color(0xFF15222B),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  StepTrackGroupModel? get _activeGroup {
    if (_groups.isEmpty) return null;
    return _groups.firstWhere(
      (g) => g.id == _activeGroupId,
      orElse: () => _groups.last,
    );
  }

  int get _activeSteps {
    if (_rangeIndex == 0) {
      return _stepsByDay[_dateKey(_selectedDate)] ?? 0;
    } else if (_rangeIndex == 1) {
      int sum = 0;
      for (int i = 0; i < 7; i++) {
        final d = _selectedDate.subtract(Duration(days: i));
        sum += _stepsByDay[_dateKey(d)] ?? 0;
      }
      return sum;
    } else {
      int sum = 0;
      for (int i = 0; i < 30; i++) {
        final d = _selectedDate.subtract(Duration(days: i));
        sum += _stepsByDay[_dateKey(d)] ?? 0;
      }
      return sum;
    }
  }

  int get _activeGoal {
    if (_stepsGoal <= 0) return 0;
    if (_rangeIndex == 0) return _stepsGoal;
    if (_rangeIndex == 1) return _stepsGoal * 7;
    return _stepsGoal * 30;
  }

  double get _goalProgress {
    if (_activeGoal <= 0) return 0.0;
    return (_activeSteps / _activeGoal).clamp(0.0, 1.0);
  }

  double get _strideMeters {
    if (_heightCm != null && _heightCm! > 0) {
      return (_heightCm! * 0.415) / 100.0;
    }
    return 0.72;
  }

  int get _distanceMeters => (_activeSteps * _strideMeters).round();

  int get _activeMinutes => (_activeSteps / 100.0).round();

  int get _caloriesKcal {
    final weightFactor = (_weightKg != null && _weightKg! > 0)
        ? (_weightKg! / 65.0)
        : 1.0;
    return (_activeSteps * 0.04 * weightFactor).round();
  }

  String? get _bmiText {
    if (_weightKg == null ||
        _heightCm == null ||
        _weightKg! <= 0 ||
        _heightCm! <= 0) {
      return null;
    }
    final hMeters = _heightCm! / 100.0;
    final bmi = _weightKg! / (hMeters * hMeters);
    return bmi.toStringAsFixed(1);
  }

  String get _formattedWeightText {
    if (_weightKg == null || _weightKg! <= 0) return 'Set Weight';
    final bool isWhole = (_weightKg! - _weightKg!.roundToDouble()).abs() < 0.05;
    return isWhole
        ? '${_weightKg!.round()} kg'
        : '${_weightKg!.toStringAsFixed(1)} kg';
  }

  Future<void> _openPlayStoreCalApp() async {
    try {
      final uri = Uri.parse(_calAppPlayStoreUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched || !mounted) return;
      Get.snackbar(
        'Play Store',
        'Play Store link open nahi ho saka.',
        backgroundColor: const Color(0xFF15222B),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error, stackTrace) {
      debugPrint('Could not open the Play Store link: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        Get.snackbar(
          'Play Store',
          'Play Store link open nahi ho saka.',
          backgroundColor: const Color(0xFF15222B),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _shareProgress() async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text:
              'StepTrack (${_displayDate(_selectedDate)}): $_activeSteps steps, $_caloriesKcal kcal, $_distanceMeters m.',
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Could not share the StepTrack progress: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        Get.snackbar(
          'Share unavailable',
          'StepTrack progress could not be shared.',
          backgroundColor: const Color(0xFF15222B),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _onQuickActionSelected(_QuickActionType action) async {
    switch (action) {
      case _QuickActionType.trackCalories:
        await Get.to(() => const TrackCaloriesScreen());
        break;
      case _QuickActionType.weightLossPlan:
        await Get.to(
          () => WeightLossPlanScreen(
            currentGoal: _stepsGoal,
            onPlanActivated: () => _syncFromSavedUserData(),
          ),
        );
        break;
      case _QuickActionType.weight:
        await Get.to(
          () => WeightScreen(
            currentWeightKg: _weightKg,
            currentHeightCm: _heightCm,
            onSaved: () => _syncFromSavedUserData(),
          ),
          opaque: false,
          transition: Transition.downToUp,
        );
        break;
      case _QuickActionType.createGroup:
        final createdGroup = await Get.to<StepTrackGroupModel>(
          () => CreateGroupScreen(
            onGroupCreated: (grp) {
              if (!mounted) return;
              setState(() => _showNewPublicGroupBanner = true);
              unawaited(_selectActiveGroup(grp.id));
              _syncFromSavedUserData();
            },
          ),
        );
        if (createdGroup != null && mounted) {
          setState(() => _showNewPublicGroupBanner = true);
          unawaited(_selectActiveGroup(createdGroup.id));
        }
        break;
      case _QuickActionType.createChallenge:
        await Get.to(
          () => CreateChallengeScreen(
            defaultTargetSteps: _stepsGoal,
            onChallengeSaved: () => _syncFromSavedUserData(),
          ),
        );
        break;
      case _QuickActionType.inviteFriend:
        await InviteFriendHelper.shareInviteLink(
          authService: _authService,
          senderName: _userName,
          firestore: _firestore,
        );
        break;
    }

    if (mounted) {
      _syncFromSavedUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    switch (_navIndex) {
      case 1:
        currentBody =
            widget.discoverScreen ?? _buildUnavailableTab('Discover');
        break;
      case 2:
        currentBody = widget.chatsScreen ?? _buildUnavailableTab('Chats');
        break;
      case 3:
        currentBody =
            widget.insightsScreen ?? _buildUnavailableTab('Insights');
        break;
      default:
        currentBody = _buildDashboardBody();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF06080A),
      body: SafeArea(
        child: Stack(
          children: [
            currentBody,
            if (_isQuickMenuOpen && _navIndex == 0) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _isQuickMenuOpen = false),
                  child: Container(color: Colors.black.withValues(alpha: 0.45)),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 84,
                child: _QuickActionMenuCard(
                  onSelectAction: (action) {
                    setState(() => _isQuickMenuOpen = false);
                    _onQuickActionSelected(action);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: _navIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                setState(() => _isQuickMenuOpen = !_isQuickMenuOpen);
              },
              backgroundColor: const Color(0xFF4FD0F8),
              foregroundColor: const Color(0xFF081016),
              shape: const CircleBorder(),
              child: Icon(_isQuickMenuOpen ? Icons.close : Icons.add, size: 28),
            )
          : null,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildUnavailableTab(String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.hourglass_empty_rounded,
              color: Color(0xFF4FD0F8),
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              '$title is not configured yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFB7C2CE),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardBody() {
    final String dateLabel = _displayDate(_selectedDate);
    final String goalSubtitle = _activeGoal > 0
        ? 'of ${_formatNumber(_activeGoal)} steps'
        : 'Tap Goals to set target';

    final visibleChallenges = _challenges
        .where((c) => !c.hiddenInHomeTab)
        .toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header: Avatar | D W M | Share
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  final ctrl = Get.isRegistered<AuthController>()
                      ? Get.find<AuthController>()
                      : Get.put(AuthController());
                  ctrl.skipToOnboarding();
                },
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _avatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _userInitial,
                    style: const TextStyle(
                      color: Color(0xFF101317),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF12171E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: List.generate(3, (index) {
                    const labels = ['D', 'W', 'M'];
                    final bool active = _rangeIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _rangeIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF202B37)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          labels[index],
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : const Color(0xFF7D858E),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              IconButton(
                onPressed: _shareProgress,
                icon: const Icon(
                  Icons.share_outlined,
                  color: Color(0xFFB7C2CE),
                  size: 21,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Step Ring + Date Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(
                      Duration(
                        days: _rangeIndex == 0
                            ? 1
                            : (_rangeIndex == 1 ? 7 : 30),
                      ),
                    );
                  });
                },
                icon: const Icon(
                  Icons.chevron_left,
                  color: Color(0xFF8B96A3),
                  size: 26,
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final ringSize = math.min(
                      230.0,
                      math.max(0.0, constraints.maxWidth),
                    );
                    return SizedBox(
                      width: ringSize,
                      height: ringSize,
                      child: CustomPaint(
              painter: _StepRingPainter(progress: _goalProgress),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: Color(0xFF4FD0F8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatNumber(_activeSteps),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goalSubtitle,
                    style: const TextStyle(
                      color: Color(0xFF7D858E),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(
                      Duration(
                        days: _rangeIndex == 0
                            ? 1
                            : (_rangeIndex == 1 ? 7 : 30),
                      ),
                    );
                  });
                },
                icon: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF8B96A3),
                  size: 26,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Quick Metrics Strip: Streak, kcal, m, mins, Insights
          SizedBox(
            height: 68,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _StatPillItem(
                  topIcon: Icons.local_fire_department_rounded,
                  topIconColor: const Color(0xFFFF8A1E),
                  value: '$_streakDays',
                  label: 'Streak',
                  labelColor: const Color(0xFFFF8A1E),
                ),
                const SizedBox(width: 10),
                _StatPillItem(value: '$_caloriesKcal', label: 'kcal'),
                const SizedBox(width: 10),
                _StatPillItem(value: '$_distanceMeters', label: 'm'),
                const SizedBox(width: 10),
                _StatPillItem(value: '$_activeMinutes', label: 'mins'),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => setState(() => _navIndex = 3),
                  child: const _StatPillItem(
                    topIcon: Icons.bar_chart_rounded,
                    topIconColor: Color(0xFF4FD0F8),
                    value: '',
                    label: 'Insights',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Hourly Timeline Bar
          Container(
            height: 82,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF10151C),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1B2430)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '6',
                      style: TextStyle(color: Color(0xFF67727E), fontSize: 10),
                    ),
                    Text(
                      '9',
                      style: TextStyle(color: Color(0xFF67727E), fontSize: 10),
                    ),
                    Text(
                      '12',
                      style: TextStyle(color: Color(0xFF67727E), fontSize: 10),
                    ),
                    Text(
                      '3',
                      style: TextStyle(color: Color(0xFF67727E), fontSize: 10),
                    ),
                    Text(
                      '6',
                      style: TextStyle(color: Color(0xFF67727E), fontSize: 10),
                    ),
                    Text(
                      '9',
                      style: TextStyle(color: Color(0xFF67727E), fontSize: 10),
                    ),
                    Text(
                      '12',
                      style: TextStyle(color: Color(0xFF67727E), fontSize: 10),
                    ),
                  ],
                ),
                const _TimelineDotsBar(),
                Container(
                  height: 3,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FD0F8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Friends + Created Groups Horizontal Strip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      _onQuickActionSelected(_QuickActionType.inviteFriend),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF102A3A),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 15,
                          color: Color(0xFF4FD0F8),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Friends',
                          style: TextStyle(
                            color: Color(0xFF4FD0F8),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Color(0xFF4FD0F8),
                        ),
                      ],
                    ),
                  ),
                ),
                ..._groups.map((grp) {
                  final bool isSelected = _activeGroup?.id == grp.id;
                  final Color grpColor = Color(grp.avatarColorValue);
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: () => _selectActiveGroup(grp.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF122C3C)
                              : const Color(0xFF141920),
                          borderRadius: BorderRadius.circular(18),
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFF4FD0F8),
                                  width: 1.2,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: grpColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                grp.initial,
                                style: const TextStyle(
                                  color: Color(0xFF0A0D10),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              grp.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: Color(0xFF4FD0F8),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 10),
                const Text(
                  '...',
                  style: TextStyle(
                    color: Color(0xFF6D7784),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Friends / Active Group Leaderboard Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF10151C),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF19222E)),
            ),
            child: Column(
              children: [
                if (_activeGroup != null && _showNewPublicGroupBanner)
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 2, 12, 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2028),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _onQuickActionSelected(
                              _QuickActionType.createGroup,
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NEW: Public Groups',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Tap here to edit your group.',
                                  style: TextStyle(
                                    color: Color(0xFF7D858E),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showNewPublicGroupBanner = false),
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFF7D858E),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_activeGroup != null)
                  InkWell(
                    onTap: () => setState(() => _navIndex = 2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00B8D4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_rounded,
                              color: Color(0xFF081016),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${_activeGroup!.name} Chat',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF8E99A6),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        child: Text(
                          '1',
                          style: TextStyle(
                            color: Color(0xFF8E99A6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _avatarColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _userInitial,
                          style: const TextStyle(
                            color: Color(0xFF101317),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF132D3E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Me',
                          style: TextStyle(
                            color: Color(0xFF4FD0F8),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatNumber(_activeSteps),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            dateLabel,
                            style: const TextStyle(
                              color: Color(0xFF6E7885),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_activeGroup != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => _onQuickActionSelected(
                          _QuickActionType.inviteFriend,
                        ),
                        icon: const Icon(
                          Icons.person_add_alt_1_outlined,
                          size: 18,
                        ),
                        label: const Text(
                          'Add Friends',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1F27),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ...List.generate(2, (idx) {
                    final rank = idx + 2;
                    final friendName = idx < _invitedFriends.length
                        ? _invitedFriends[idx]
                        : null;
                    return InkWell(
                      onTap: () =>
                          _onQuickActionSelected(_QuickActionType.inviteFriend),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              child: Text(
                                '$rank',
                                style: const TextStyle(
                                  color: Color(0xFF8E99A6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF3A4554),
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 16,
                                color: Color(0xFF8E99A6),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              friendName ?? 'Invite someone',
                              style: TextStyle(
                                color: friendName != null
                                    ? Colors.white
                                    : const Color(0xFF8E99A6),
                                fontSize: 14,
                                fontWeight: friendName != null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),

          // Active Challenges List on Home
          if (visibleChallenges.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...visibleChallenges.map((chl) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () async {
                    await Get.to(
                      () => ChallengeDetailScreen(
                        challenge: chl,
                        onUpdated: () => _syncFromSavedUserData(),
                      ),
                    );
                    if (mounted) _syncFromSavedUserData();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10151C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF19222E)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chl.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF4FD0F8),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatNumber(chl.dailyGoalSteps)} steps for ${chl.durationDays} days',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF8E99A6),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 14),

          // Goals & Weight Cards
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      _onQuickActionSelected(_QuickActionType.createChallenge),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10151C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF19222E)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.track_changes_rounded,
                              color: Color(0xFF4FD0F8),
                              size: 18,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Goals',
                              style: TextStyle(
                                color: Color(0xFF4FD0F8),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _stepsGoal > 0
                              ? _formatNumber(_stepsGoal)
                              : 'Set Goal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Steps Goal',
                          style: TextStyle(
                            color: Color(0xFF7D858E),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _onQuickActionSelected(_QuickActionType.weight),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10151C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF19222E)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.monitor_weight_outlined,
                              color: Color(0xFF4FD0F8),
                              size: 18,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Weight',
                              style: TextStyle(
                                color: Color(0xFF4FD0F8),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _formattedWeightText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _bmiText != null ? 'BMI: $_bmiText' : 'BMI: --',
                          style: const TextStyle(
                            color: Color(0xFF7D858E),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Awards & Insights Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10151C),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF19222E)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.settings_outlined,
                            color: Color(0xFF4FD0F8),
                            size: 18,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'Awards',
                            style: TextStyle(
                              color: Color(0xFF4FD0F8),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(3, (i) {
                          final unlocked = _activeSteps >= ((i + 1) * 2000);
                          return Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: unlocked
                                  ? const Color(0xFF163244)
                                  : const Color(0xFF1B2027),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.workspace_premium_outlined,
                              size: 18,
                              color: unlocked
                                  ? const Color(0xFF4FD0F8)
                                  : const Color(0xFF49525E),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _navIndex = 3),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10151C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF19222E)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.bar_chart_rounded,
                              color: Color(0xFF4FD0F8),
                              size: 18,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Insights',
                              style: TextStyle(
                                color: Color(0xFF4FD0F8),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Container(
                              height: 3,
                              width: 44,
                              color: const Color(0xFFE53935),
                            ),
                            Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10151C),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 2,
                                color: const Color(0xFF28313D),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Weight Loss Plan Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF10151C),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF19222E)),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Weight Loss Plan',
                  style: TextStyle(
                    color: Color(0xFF4FD0F8),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Lose weight with guided walking and\nworkout sessions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7D858E),
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () =>
                        _onQuickActionSelected(_QuickActionType.weightLossPlan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A222C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Start Weight Loss Plan',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Explore Our Apps: CalApp
          const Text(
            'Explore Our Apps',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _openPlayStoreCalApp,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10151C),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF19222E)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E252E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFFF6D1F),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CalApp',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'AI Calorie Tracker',
                              style: TextStyle(
                                color: Color(0xFF7D858E),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _openPlayStoreCalApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E2733),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Get',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Effortlessly track calories with our AI-powered calorie tracker.',
                    style: TextStyle(
                      color: Color(0xFF8E99A6),
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 165,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF57C00),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 112,
                      height: 145,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E1318),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu_rounded,
                            color: Color(0xFF4FD0F8),
                            size: 32,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'CalApp AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0E13),
        border: Border(top: BorderSide(color: Color(0xFF17202B), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (index) => setState(() {
          _navIndex = index;
          _isQuickMenuOpen = false;
        }),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0A0E13),
        selectedItemColor: const Color(0xFF4FD0F8),
        unselectedItemColor: const Color(0xFF7D858E),
        selectedFontSize: 11.5,
        unselectedFontSize: 11.5,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.search),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_outline),
                if (_invitedFriends.isNotEmpty)
                  Positioned(
                    right: -6,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_invitedFriends.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: const Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'Insights',
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buf.write(',');
      }
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

enum _QuickActionType {
  trackCalories,
  weight,
  weightLossPlan,
  createGroup,
  createChallenge,
  inviteFriend,
}

class _QuickActionMenuCard extends StatelessWidget {
  final ValueChanged<_QuickActionType> onSelectAction;

  const _QuickActionMenuCard({required this.onSelectAction});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF14181F),
      elevation: 10,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 248,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF14181F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF232B36)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _menuTile(
              icon: Icons.local_fire_department_rounded,
              iconColor: const Color(0xFFFF6D1F),
              title: 'Track Calories',
              onTap: () => onSelectAction(_QuickActionType.trackCalories),
            ),
            const Divider(height: 1, color: Color(0xFF222A35)),
            _menuTile(
              icon: Icons.monitor_weight_outlined,
              iconColor: const Color(0xFF4FD0F8),
              title: 'Weight',
              onTap: () => onSelectAction(_QuickActionType.weight),
            ),
            const Divider(height: 1, color: Color(0xFF222A35)),
            _menuTile(
              icon: Icons.assignment_turned_in_outlined,
              iconColor: const Color(0xFF2979FF),
              title: 'Weight Loss Plan',
              onTap: () => onSelectAction(_QuickActionType.weightLossPlan),
            ),
            const Divider(height: 1, color: Color(0xFF222A35)),
            _menuTile(
              icon: Icons.group_add_outlined,
              iconColor: Colors.white,
              title: 'Create Group',
              onTap: () => onSelectAction(_QuickActionType.createGroup),
            ),
            const Divider(height: 1, color: Color(0xFF222A35)),
            _menuTile(
              icon: Icons.emoji_events_outlined,
              iconColor: Colors.white,
              title: 'Create Challenge',
              onTap: () => onSelectAction(_QuickActionType.createChallenge),
            ),
            const Divider(height: 1, color: Color(0xFF222A35)),
            _menuTile(
              icon: Icons.person_add_alt_1_outlined,
              iconColor: Colors.white,
              title: 'Invite Friend',
              onTap: () => onSelectAction(_QuickActionType.inviteFriend),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRingPainter extends CustomPainter {
  final double progress;

  const _StepRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 12;
    const strokeWidth = 14.0;

    final trackPaint = Paint()
      ..color = const Color(0xFF171E26)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = const Color(0xFF4FD0F8)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StepRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _StatPillItem extends StatelessWidget {
  final IconData? topIcon;
  final Color? topIconColor;
  final String value;
  final String label;
  final Color? labelColor;

  const _StatPillItem({
    this.topIcon,
    this.topIconColor,
    required this.value,
    required this.label,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10151C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF19222E)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (topIcon != null)
            Icon(
              topIcon,
              size: 16,
              color: topIconColor ?? const Color(0xFF4FD0F8),
            )
          else
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: labelColor ?? const Color(0xFF8E99A6),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineDotsBar extends StatelessWidget {
  const _TimelineDotsBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(25, (index) {
        final isMajor = index % 4 == 0;
        return Container(
          width: isMajor ? 4 : 2.5,
          height: isMajor ? 4 : 2.5,
          decoration: BoxDecoration(
            color: isMajor ? const Color(0xFF7D858E) : const Color(0xFF3E4752),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

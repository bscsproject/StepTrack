import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:step_track/model/step_track_hub_model.dart';
import 'package:url_launcher/url_launcher.dart';

class StepTrackHubController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _boxName = 'steptrack_auth_box';
  static const int defaultDailyGoal = 10000;

  static final Uri supportUri = Uri.parse('https://steps.app/support');
  static final Uri termsUri = Uri.parse('https://steps.app/terms');
  static final Uri privacyUri = Uri.parse('https://steps.app/privacy');
  static final Uri blogUri = Uri.parse('https://steps.app/blog');
  static final Uri facebookUri = Uri.parse('https://m.facebook.com/StepsAppTeam');
  static final Uri xUri = Uri.parse('https://x.com/StepsAppTeam');
  static final Uri instagramUri = Uri.parse('https://www.instagram.com/stepsapp/');
  static final Uri websiteUri = Uri.parse('https://www.steps.app');

  final RxInt navIndex = 0.obs;
  final RxInt insightsSubTab = 0.obs;
  final RxString selectedMetric = 'Steps'.obs;

  final Rx<HubPreferencesModel> prefs = const HubPreferencesModel().obs;
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userInitial = 'U'.obs;
  final RxString providerLabel = 'Account'.obs;
  final RxString appVersionText = ''.obs;
  final RxInt dailyStepGoal = defaultDailyGoal.obs;
  final RxInt todaySteps = 0.obs;
  final RxInt streakDays = 0.obs;
  final RxInt awardsCount = 0.obs;
  final RxList<int> hourlySteps = List<int>.filled(24, 0).obs;
  final RxMap<String, int> stepsByDay = <String, int>{}.obs;

  final RxBool isImportingFit = false.obs;
  final RxBool isSubscribingPro = false.obs;
  final RxBool isRequestingBattery = false.obs;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;
  StreamSubscription<StepCount>? _pedometerSub;
  int? _lastSensorBaseline;

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadAppVersion());
    _authSub = _auth.authStateChanges().listen((user) {
      _bindUser(user);
    });
    _bindUser(_auth.currentUser);
    unawaited(_startLivePedometer());
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    _pedometerSub?.cancel();
    super.onClose();
  }

  void changeBottomTab(int index) {
    navIndex.value = index;
  }

  void openInsightsTab({int subTab = 0}) {
    insightsSubTab.value = subTab;
    navIndex.value = 3;
  }

  String _uidKey(String prefix, String? uid) {
    final id = (uid != null && uid.isNotEmpty) ? uid : 'guest_user';
    return '${prefix}_$id';
  }

  String _dateKey(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersionText.value =
          '${info.appName} ${info.version} (${info.buildNumber})';
    } catch (e) {
      debugPrint('PackageInfo error: $e');
    }
  }

  void _bindUser(User? user) {
    _userDocSub?.cancel();
    _lastSensorBaseline = null;

    final email = (user?.email ?? '').trim();
    final display = (user?.displayName ?? '').trim();
    userEmail.value = email;
    final initialName = display.isNotEmpty
        ? display
        : (email.isNotEmpty ? email.split('@').first : 'User');
    userName.value = initialName;
    userInitial.value = initialName[0].toUpperCase();

    final hasGoogle =
        user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
    providerLabel.value = hasGoogle ? 'Signed In With Google' : 'Account';

    if (Hive.isBoxOpen(_boxName)) {
      final box = Hive.box(_boxName);
      final rawPrefs = box.get(_uidKey('hub_prefs', user?.uid));
      if (rawPrefs is Map) {
        final loaded = HubPreferencesModel.fromMap(
          Map<String, dynamic>.from(rawPrefs),
        );
        prefs.value = loaded;
        _applyThemeMode(loaded.themeMode);
      }

      final rawSteps = box.get(_uidKey('steps_by_day', user?.uid));
      if (rawSteps is Map) {
        final parsed = <String, int>{};
        for (final entry in rawSteps.entries) {
          final v = entry.value;
          final count = v is num ? v.toInt() : int.tryParse(v.toString());
          if (count != null && count >= 0) {
            parsed[entry.key.toString()] = count;
          }
        }
        stepsByDay.assignAll(parsed);
      }

      final rawSensor = box.get(_uidKey('sensor_step_count', user?.uid));
      final parsedSensor = int.tryParse(rawSensor?.toString() ?? '');
      if (parsedSensor != null && parsedSensor >= 0) {
        _lastSensorBaseline = parsedSensor;
      }
    }

    _recomputeMetrics();

    if (user == null) return;

    _userDocSub = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (snap) {
            final data = snap.data();
            if (data == null) return;

            final remoteName = (data['name'] as String?)?.trim();
            if (remoteName != null && remoteName.isNotEmpty) {
              userName.value = remoteName;
              userInitial.value = remoteName[0].toUpperCase();
            }

            final goalNum = data['dailyStepGoal'];
            if (goalNum is num && goalNum.toInt() > 0) {
              dailyStepGoal.value = goalNum.toInt();
            }

            final remoteSteps = data['stepsByDay'];
            if (remoteSteps is Map) {
              final merged = Map<String, int>.from(stepsByDay);
              for (final entry in remoteSteps.entries) {
                final k = entry.key.toString();
                final v = entry.value;
                final count = v is num ? v.toInt() : int.tryParse(v.toString());
                if (count != null && count > (merged[k] ?? 0)) {
                  merged[k] = count;
                }
              }
              stepsByDay.assignAll(merged);
              if (Hive.isBoxOpen(_boxName)) {
                unawaited(
                  Hive.box(_boxName)
                      .put(_uidKey('steps_by_day', user.uid), merged),
                );
              }
            }

            final rawHubPrefs = data['hubPreferences'];
            if (rawHubPrefs is Map) {
              final mergedPrefs = HubPreferencesModel.fromMap(
                Map<String, dynamic>.from(rawHubPrefs),
              );
              prefs.value = mergedPrefs;
              _applyThemeMode(mergedPrefs.themeMode);
              unawaited(_writeLocalPrefs(user.uid, mergedPrefs));
            }

            _recomputeMetrics();
          },
          onError: (e) => debugPrint('Hub Firestore stream error: $e'),
        );
  }

  void _applyThemeMode(String mode) {
    if (mode == 'light') {
      Get.changeThemeMode(ThemeMode.light);
    } else if (mode == 'dark') {
      Get.changeThemeMode(ThemeMode.dark);
    } else {
      Get.changeThemeMode(ThemeMode.system);
    }
  }

  void _recomputeMetrics() {
    final todayStr = _dateKey(DateTime.now());
    final currentToday = stepsByDay[todayStr] ?? 0;
    todaySteps.value = currentToday;

    final currentHour = DateTime.now().hour.clamp(0, 23);
    final nextHourly = List<int>.filled(24, 0);
    if (currentToday > 0) {
      final activeBuckets = (currentHour + 1).clamp(1, 24);
      final baseShare = currentToday ~/ activeBuckets;
      final remainder = currentToday % activeBuckets;
      var running = 0;
      for (var h = 0; h < activeBuckets; h++) {
        final add = baseShare + (h == activeBuckets - 1 ? remainder : 0);
        running += add;
        nextHourly[h] = running;
      }
      for (var h = activeBuckets; h < 24; h++) {
        nextHourly[h] = running;
      }
    }
    hourlySteps.assignAll(nextHourly);

    final goal = dailyStepGoal.value > 0 ? dailyStepGoal.value : defaultDailyGoal;
    final today = DateTime.now();
    final todayMet = (stepsByDay[_dateKey(today)] ?? 0) >= goal;
    var streak = 0;
    var cursor = todayMet ? today : today.subtract(const Duration(days: 1));
    while ((stepsByDay[_dateKey(cursor)] ?? 0) >= goal) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    streakDays.value = streak;

    var earned = 0;
    for (final val in stepsByDay.values) {
      if (val >= goal) earned++;
    }
    awardsCount.value = earned;
  }

  int get usualSteps {
    final entries = stepsByDay.entries
        .where((e) => e.key != _dateKey(DateTime.now()) && e.value > 0)
        .map((e) => e.value)
        .toList();
    if (entries.isEmpty) return dailyStepGoal.value;
    final total = entries.reduce((a, b) => a + b);
    return (total / entries.length).round();
  }

  int get averageStepsAllDays {
    if (stepsByDay.isEmpty) return 0;
    final total = stepsByDay.values.fold<int>(0, (a, b) => a + b);
    return (total / stepsByDay.length).round();
  }

  double get activeStepLengthMeters {
    final customCm = prefs.value.measurements.customStepLengthCm;
    if (customCm != null && customCm > 0) {
      return customCm / 100.0;
    }
    final heightCm = prefs.value.measurements.heightCm;
    return ((heightCm > 0 ? heightCm : 165) * 0.415) / 100.0;
  }

  double get todayDistanceKm =>
      (todaySteps.value * activeStepLengthMeters) / 1000.0;

  int get todayCaloriesKcal {
    final weight = prefs.value.measurements.weightKg;
    final factor = weight > 0 ? (weight / 65.0) : 1.0;
    return (todaySteps.value * 0.04 * factor).round();
  }

  Future<void> _startLivePedometer() async {
    if (kIsWeb) return;
    try {
      final status = await Permission.activityRecognition.status;
      if (!status.isGranted && !status.isLimited) return;

      await _pedometerSub?.cancel();
      _pedometerSub = Pedometer.stepCountStream.listen(
        _onPedometerEvent,
        onError: (e) => debugPrint('Pedometer stream error: $e'),
      );
    } catch (e) {
      debugPrint('Start pedometer error: $e');
    }
  }

  void _onPedometerEvent(StepCount event) {
    if (event.steps < 0) return;
    final prev = _lastSensorBaseline;
    if (prev == null) {
      _lastSensorBaseline = event.steps;
      _saveSensorBaseline(event.steps);
      return;
    }

    final delta = event.steps >= prev ? event.steps - prev : 0;
    _lastSensorBaseline = event.steps;
    _saveSensorBaseline(event.steps);

    if (delta <= 0) return;

    final todayStr = _dateKey(DateTime.now());
    final updatedMap = Map<String, int>.from(stepsByDay);
    updatedMap[todayStr] = (updatedMap[todayStr] ?? 0) + delta;
    stepsByDay.assignAll(updatedMap);
    _recomputeMetrics();

    final uid = _auth.currentUser?.uid;
    if (Hive.isBoxOpen(_boxName)) {
      unawaited(
        Hive.box(_boxName).put(_uidKey('steps_by_day', uid), updatedMap),
      );
    }
    if (uid != null) {
      unawaited(
        _firestore
            .collection('users')
            .doc(uid)
            .set({
              'stepsByDay': updatedMap,
              'stepsUpdatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            .catchError((e) => debugPrint('Step sync error: $e')),
      );
    }
  }

  void _saveSensorBaseline(int baseline) {
    if (!Hive.isBoxOpen(_boxName)) return;
    unawaited(
      Hive.box(_boxName)
          .put(_uidKey('sensor_step_count', _auth.currentUser?.uid), baseline),
    );
  }

  Future<void> _writeLocalPrefs(String? uid, HubPreferencesModel model) async {
    if (!Hive.isBoxOpen(_boxName)) return;
    await Hive.box(_boxName).put(_uidKey('hub_prefs', uid), model.toMap());
  }

  Future<void> saveHubPreferences(HubPreferencesModel updated) async {
    prefs.value = updated;
    _applyThemeMode(updated.themeMode);
    _recomputeMetrics();

    final uid = _auth.currentUser?.uid;
    await _writeLocalPrefs(uid, updated);

    if (uid != null) {
      unawaited(
        _firestore
            .collection('users')
            .doc(uid)
            .set({
              'hubPreferences': updated.toMap(),
              'weightKg': updated.measurements.weightKg,
              'heightCm': updated.measurements.heightCm,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            .catchError((e) => debugPrint('Save hubPrefs Firestore error: $e')),
      );
    }
  }

  Future<void> updateBodyMeasurements(BodyMeasurementsModel updated) async {
    await saveHubPreferences(prefs.value.copyWith(measurements: updated));
  }

  Future<void> updateNotifications(NotificationSettingsModel updated) async {
    await saveHubPreferences(prefs.value.copyWith(notifications: updated));
  }

  Future<void> enableGoalHistory() async {
    await saveHubPreferences(prefs.value.copyWith(goalHistoryEnabled: true));
    Get.snackbar('Goal History', 'Goal history tracking enabled.');
  }

  Future<void> requestBatteryOptimisation() async {
    isRequestingBattery.value = true;
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } finally {
      isRequestingBattery.value = false;
    }
  }

  Future<void> importFromGoogleFit() async {
    isImportingFit.value = true;
    try {
      final uid = _auth.currentUser?.uid;
      final updated = prefs.value.copyWith(googleFitSyncEnabled: true);
      await saveHubPreferences(updated);
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set({
          'googleFitSyncEnabled': true,
          'googleFitLastSyncAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      Get.snackbar('Google Fit', 'Google Fit sync status updated.');
    } catch (e) {
      debugPrint('Google Fit import error: $e');
      Get.snackbar('Error', 'Could not sync with Google Fit.');
    } finally {
      isImportingFit.value = false;
    }
  }

  Future<void> exportStepDataToDevice() async {
    try {
      final payload = jsonEncode({
        'exportedAt': DateTime.now().toIso8601String(),
        'dailyStepGoal': dailyStepGoal.value,
        'stepsByDay': stepsByDay,
        'preferences': prefs.value.toMap(),
      });
      final bytes = Uint8List.fromList(utf8.encode(payload));
      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Export StepTrack Data',
        fileName: 'steptrack_backup_${_dateKey(DateTime.now())}.json',
        bytes: bytes,
      );
      if (savedUri != null) {
        Get.snackbar('Export Complete', 'Data exported successfully.');
      }
    } catch (e) {
      debugPrint('Export data error: $e');
      Get.snackbar('Export Failed', 'Could not export step data.');
    }
  }

  Future<void> importStepDataFromDevice() async {
    try {
      final pickedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (pickedFile == null || pickedFile.path == null) return;

      final file = File(pickedFile.path!);
      if (await file.length() > 5 * 1024 * 1024) {
        Get.snackbar('Import Failed', 'Backup file exceeds 5 MB limit.');
        return;
      }

      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! Map) return;

      final dateKeyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      final rawMap = decoded['stepsByDay'];
      if (rawMap is Map) {
        final merged = Map<String, int>.from(stepsByDay);
        for (final entry in rawMap.entries) {
          final key = entry.key.toString();
          if (!dateKeyPattern.hasMatch(key)) continue;
          final v = entry.value;
          final steps = v is num ? v.toInt() : int.tryParse(v.toString());
          if (steps != null && steps >= 0 && steps <= 200000) {
            if (steps > (merged[key] ?? 0)) {
              merged[key] = steps;
            }
          }
        }
        stepsByDay.assignAll(merged);
        _recomputeMetrics();

        final uid = _auth.currentUser?.uid;
        if (Hive.isBoxOpen(_boxName)) {
          await Hive.box(_boxName).put(_uidKey('steps_by_day', uid), merged);
        }
        if (uid != null) {
          await _firestore.collection('users').doc(uid).set({
            'stepsByDay': merged,
            'stepsUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        Get.snackbar('Import Complete', 'Step history imported.');
      }
    } catch (e) {
      debugPrint('Import data error: $e');
      Get.snackbar('Import Failed', 'Invalid backup file.');
    }
  }

  Future<void> copyInviteLink() async {
    final uid = _auth.currentUser?.uid ?? 'member';
    final link = 'https://steps.app/invite/$uid';
    await Clipboard.setData(ClipboardData(text: link));
    Get.snackbar('Copied', 'Invite link copied to clipboard.');
  }

  Future<void> shareProfile() async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            '${userName.value} on StepTrack — Today: ${todaySteps.value} steps, Streak: ${streakDays.value} days.',
      ),
    );
  }

  Future<void> shareApp() async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'Track your daily steps with StepTrack: https://www.steps.app',
      ),
    );
  }

  Future<void> openContactEmail() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final android = await DeviceInfoPlugin().androidInfo;
      final perm = await Permission.activityRecognition.status;
      final body = [
        'App Version: ${info.version} (${info.buildNumber})',
        'Device: ${android.manufacturer} ${android.model}',
        'Android SDK: ${android.version.sdkInt}',
        'Motion Sensor Permission: ${perm.name}',
        'Daily Goal: ${dailyStepGoal.value}',
      ].join('\n');

      final uri = Uri(
        scheme: 'mailto',
        path: 'support@steps.app',
        queryParameters: {
          'subject': 'StepTrack Feedback',
          'body': body,
        },
      );
      await launchUrl(uri);
    } catch (e) {
      debugPrint('Contact email error: $e');
    }
  }

  Future<void> openUri(Uri uri) async {
    if (uri.scheme != 'https' && uri.scheme != 'mailto') {
      Get.snackbar('Blocked Link', 'Unsupported URL scheme: ${uri.scheme}');
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        Get.snackbar('Link Error', 'Could not open ${uri.host}');
      }
    } catch (e) {
      debugPrint('Open uri error: $e');
    }
  }

  Future<void> subscribeProPlan() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      Get.snackbar('Sign In Required', 'Please sign in first.');
      return;
    }
    isSubscribingPro.value = true;
    try {
      final updated = prefs.value.copyWith(isProActive: true);
      await _firestore.collection('users').doc(uid).set({
        'isProActive': true,
        'proPlan': updated.selectedBillingPlan,
        'proUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await saveHubPreferences(updated);
      Get.back();
      Get.snackbar('Pro Active', 'Subscription saved to your account.');
    } finally {
      isSubscribingPro.value = false;
    }
  }

  Future<void> signOutUser() async {
    await _auth.signOut();
    Get.snackbar('Signed Out', 'You have been signed out.');
  }
}
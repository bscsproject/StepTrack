import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:step_track/services/auth_service.dart';

class StepTrackChallengeModel {
  final String id;
  final String title;
  final String challengeType;
  final int dailyGoalSteps;
  final int durationDays;
  final String startDateIso;
  final int accentColorValue;
  final bool isPublic;
  final String whoCanChat;
  final bool isRecurring;
  final bool isTeamMode;
  final bool hiddenInHomeTab;
  final List<String> participants;
  final List<int> completedDayIndices;

  const StepTrackChallengeModel({
    required this.id,
    required this.title,
    required this.challengeType,
    required this.dailyGoalSteps,
    required this.durationDays,
    required this.startDateIso,
    required this.accentColorValue,
    required this.isPublic,
    required this.whoCanChat,
    required this.isRecurring,
    required this.isTeamMode,
    this.hiddenInHomeTab = false,
    this.participants = const [],
    this.completedDayIndices = const [],
  });

  DateTime get startDate =>
      DateTime.tryParse(startDateIso) ?? DateTime.now();

  DateTime get endDate =>
      startDate.add(Duration(days: durationDays > 0 ? durationDays : 7));

  String get inviteLink => 'https://steptrack.app/challenge/$id';

  StepTrackChallengeModel copyWith({
    String? id,
    String? title,
    String? challengeType,
    int? dailyGoalSteps,
    int? durationDays,
    String? startDateIso,
    int? accentColorValue,
    bool? isPublic,
    String? whoCanChat,
    bool? isRecurring,
    bool? isTeamMode,
    bool? hiddenInHomeTab,
    List<String>? participants,
    List<int>? completedDayIndices,
  }) {
    return StepTrackChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      challengeType: challengeType ?? this.challengeType,
      dailyGoalSteps: dailyGoalSteps ?? this.dailyGoalSteps,
      durationDays: durationDays ?? this.durationDays,
      startDateIso: startDateIso ?? this.startDateIso,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      isPublic: isPublic ?? this.isPublic,
      whoCanChat: whoCanChat ?? this.whoCanChat,
      isRecurring: isRecurring ?? this.isRecurring,
      isTeamMode: isTeamMode ?? this.isTeamMode,
      hiddenInHomeTab: hiddenInHomeTab ?? this.hiddenInHomeTab,
      participants: participants ?? this.participants,
      completedDayIndices: completedDayIndices ?? this.completedDayIndices,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'challengeType': challengeType,
      'dailyGoalSteps': dailyGoalSteps,
      'durationDays': durationDays,
      'startDateIso': startDateIso,
      'accentColorValue': accentColorValue,
      'isPublic': isPublic,
      'whoCanChat': whoCanChat,
      'isRecurring': isRecurring,
      'isTeamMode': isTeamMode,
      'hiddenInHomeTab': hiddenInHomeTab,
      'participants': participants,
      'completedDayIndices': completedDayIndices,
    };
  }

  factory StepTrackChallengeModel.fromMap(Map<String, dynamic> map) {
    final rawParticipants = map['participants'];
    final parsedParticipants = rawParticipants is List
        ? rawParticipants.map((e) => e.toString()).toList()
        : const <String>[];

    final rawDays = map['completedDayIndices'];
    final parsedDays = rawDays is List
        ? rawDays
            .map((e) => int.tryParse(e.toString()) ?? -1)
            .where((i) => i >= 0)
            .toList()
        : const <int>[];

    return StepTrackChallengeModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Daily Steps Challenge',
      challengeType: map['challengeType']?.toString() ?? 'Daily Steps',
      dailyGoalSteps:
          int.tryParse(map['dailyGoalSteps']?.toString() ?? '') ?? 10000,
      durationDays: int.tryParse(map['durationDays']?.toString() ?? '') ?? 7,
      startDateIso:
          map['startDateIso']?.toString() ?? DateTime.now().toIso8601String(),
      accentColorValue:
          int.tryParse(map['accentColorValue']?.toString() ?? '') ?? 0xFFFFB300,
      isPublic: map['isPublic'] == true,
      whoCanChat: map['whoCanChat']?.toString() ?? 'Everyone',
      isRecurring: map['isRecurring'] == true,
      isTeamMode: map['isTeamMode'] == true,
      hiddenInHomeTab: map['hiddenInHomeTab'] == true,
      participants: parsedParticipants,
      completedDayIndices: parsedDays,
    );
  }
}

class ChallengeStorageHelper {
  static const String boxName = 'steptrack_auth_box';
  static const String challengesKey = 'user_challenges_list_json';

  static List<StepTrackChallengeModel> loadChallenges() {
    if (!Hive.isBoxOpen(boxName)) return const [];
    final box = Hive.box(boxName);
    final raw = box.get(challengesKey);
    if (raw == null || raw.toString().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw.toString());
      if (decoded is List) {
        return decoded
            .whereType()
            .map((e) =>
                StepTrackChallengeModel.fromMap(Map<String, dynamic>.from(e)))
            .where((c) => c.id.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  static Future<void> saveChallenges(
    List<StepTrackChallengeModel> list, {
    String? uid,
  }) async {
    if (Hive.isBoxOpen(boxName)) {
      final box = Hive.box(boxName);
      await box.put(
        challengesKey,
        jsonEncode(list.map((e) => e.toMap()).toList()),
      );
    }

    if (uid != null && uid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'challenges': list.map((e) => e.toMap()).toList(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }
}

class CreateChallengeScreen extends StatefulWidget {
  final int defaultTargetSteps;
  final StepTrackChallengeModel? initialChallenge;
  final VoidCallback? onChallengeSaved;

  const CreateChallengeScreen({
    super.key,
    this.defaultTargetSteps = 10000,
    this.initialChallenge,
    this.onChallengeSaved,
  });

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final AuthService _authService = AuthService();

  late String _title;
  late String _challengeType;
  late int _goalSteps;
  late int _durationDays;
  late int _accentColorValue;
  late bool _isPublic;
  late String _whoCanChat;
  late bool _isRecurring;
  late bool _isTeamMode;
  bool _isSaving = false;

  final List<String> _challengeTypes = const [
    'Daily Steps',
    'Total Steps',
    'Active Streak',
  ];

  final List<int> _goalOptions = const [
    5000,
    6000,
    8000,
    10000,
    12000,
    15000,
  ];

  final List<int> _durationOptions = const [
    3,
    7,
    14,
    21,
    30,
  ];

  final List<String> _chatOptions = const [
    'Everyone',
    'Participants Only',
    'Admins Only',
  ];

  final List<Color> _accentColors = const [
    Color(0xFFFFB300), // Trophy Gold
    Color(0xFF4FD0F8), // Cyan
    Color(0xFF00E676), // Emerald Green
    Color(0xFFFF4081), // Pink
    Color(0xFF9C42F5), // Purple
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialChallenge;
    if (init != null) {
      _title = init.title;
      _challengeType = init.challengeType;
      _goalSteps = init.dailyGoalSteps;
      _durationDays = init.durationDays;
      _accentColorValue = init.accentColorValue;
      _isPublic = init.isPublic;
      _whoCanChat = init.whoCanChat;
      _isRecurring = init.isRecurring;
      _isTeamMode = init.isTeamMode;
    } else {
      _title = 'Daily Steps Challenge';
      _challengeType = 'Daily Steps';
      _goalSteps =
          widget.defaultTargetSteps > 0 ? widget.defaultTargetSteps : 10000;
      _durationDays = 7;
      _accentColorValue = 0xFFFFB300;
      _isPublic = false;
      _whoCanChat = 'Everyone';
      _isRecurring = false;
      _isTeamMode = false;
    }
  }

  String _formatNum(int n) {
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

  List<String> _dayLetters() {
    const letters = ['W', 'T', 'F', 'S', 'S', 'M', 'T'];
    final count = _durationDays.clamp(1, 7);
    return List.generate(count, (i) => letters[i % letters.length]);
  }

  Future<void> _selectFromList({
    required String title,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) async {
    await Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF141920),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ...options.map((opt) {
              final selected = opt == currentValue;
              return ListTile(
                title: Text(
                  opt,
                  style: TextStyle(
                    color: selected ? const Color(0xFF4FD0F8) : Colors.white,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check, color: Color(0xFF4FD0F8))
                    : null,
                onTap: () {
                  onSelected(opt);
                  Get.back();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _pickGoal() async {
    final customCtrl = TextEditingController(text: _goalSteps.toString());
    await Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: Color(0xFF141920),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Daily Steps Goal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _goalOptions.map((g) {
                final isSel = g == _goalSteps;
                return ChoiceChip(
                  label: Text('${_formatNum(g)} steps'),
                  selected: isSel,
                  selectedColor: const Color(0xFF4FD0F8),
                  backgroundColor: const Color(0xFF1E2631),
                  labelStyle: TextStyle(
                    color: isSel ? const Color(0xFF081016) : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) {
                    setState(() => _goalSteps = g);
                    Get.back();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: customCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Custom steps goal',
                hintStyle: const TextStyle(color: Color(0xFF7D858E)),
                filled: true,
                fillColor: const Color(0xFF0C1015),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final parsed = int.tryParse(customCtrl.text.trim());
                if (parsed != null && parsed >= 500) {
                  setState(() => _goalSteps = parsed);
                  Get.back();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FD0F8),
                foregroundColor: const Color(0xFF081016),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Apply Goal',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDuration() async {
    await Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF141920),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Duration',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ..._durationOptions.map((days) {
              final selected = days == _durationDays;
              return ListTile(
                title: Text(
                  '$days days',
                  style: TextStyle(
                    color: selected ? const Color(0xFF4FD0F8) : Colors.white,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check, color: Color(0xFF4FD0F8))
                    : null,
                onTap: () {
                  setState(() => _durationDays = days);
                  Get.back();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _openCustomizeSheet() async {
    final titleCtrl = TextEditingController(text: _title);
    int tempColor = _accentColorValue;

    await Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFF141920),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Customize Challenge',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Challenge Name',
                    labelStyle: const TextStyle(color: Color(0xFF8E99A6)),
                    filled: true,
                    fillColor: const Color(0xFF0C1015),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _accentColors.map((c) {
                    final sel = c.value == tempColor;
                    return GestureDetector(
                      onTap: () => setModalState(() => tempColor = c.value),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: sel
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final clean = titleCtrl.text.trim();
                    setState(() {
                      if (clean.isNotEmpty) _title = clean;
                      _accentColorValue = tempColor;
                    });
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FD0F8),
                    foregroundColor: const Color(0xFF081016),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Save Customization',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _onCreatePressed() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final existingList = ChallengeStorageHelper.loadChallenges();
      final now = DateTime.now();

      final challenge = widget.initialChallenge != null
          ? widget.initialChallenge!.copyWith(
              title: _title.trim().isEmpty ? 'Daily Steps Challenge' : _title.trim(),
              challengeType: _challengeType,
              dailyGoalSteps: _goalSteps,
              durationDays: _durationDays,
              accentColorValue: _accentColorValue,
              isPublic: _isPublic,
              whoCanChat: _whoCanChat,
              isRecurring: _isRecurring,
              isTeamMode: _isTeamMode,
            )
          : StepTrackChallengeModel(
              id: 'chl_${now.millisecondsSinceEpoch}',
              title: _title.trim().isEmpty ? 'Daily Steps Challenge' : _title.trim(),
              challengeType: _challengeType,
              dailyGoalSteps: _goalSteps,
              durationDays: _durationDays,
              startDateIso: now.toIso8601String(),
              accentColorValue: _accentColorValue,
              isPublic: _isPublic,
              whoCanChat: _whoCanChat,
              isRecurring: _isRecurring,
              isTeamMode: _isTeamMode,
              participants: const ['Me'],
              completedDayIndices: const [],
            );

      final index = existingList.indexWhere((c) => c.id == challenge.id);
      final updatedList = List<StepTrackChallengeModel>.from(existingList);
      if (index >= 0) {
        updatedList[index] = challenge;
      } else {
        updatedList.add(challenge);
      }

      await ChallengeStorageHelper.saveChallenges(
        updatedList,
        uid: _authService.currentUser?.uid,
      );
      await _authService.saveUserMainGoal('$_goalSteps steps');

      widget.onChallengeSaved?.call();

      if (!mounted) return;
      final savedChallenge = await Get.off<StepTrackChallengeModel>(
        () => ChallengeDetailScreen(
          challenge: challenge,
          onUpdated: () => widget.onChallengeSaved?.call(),
        ),
      );
      if (savedChallenge != null) {
        widget.onChallengeSaved?.call();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _dayLetters();
    final Color trophyColor = Color(_accentColorValue);

    return Scaffold(
      backgroundColor: const Color(0xFF05080A),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Bar: Close (X) + Cyan "Create" Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF8E99A6),
                      size: 26,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _onCreatePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FD0F8),
                      foregroundColor: const Color(0xFF081016),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      widget.initialChallenge != null ? 'Save' : 'Create',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Trophy Hero Icon
              Center(
                child: Container(
                  width: 112,
                  height: 112,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: trophyColor.withValues(alpha: 0.22),
                        blurRadius: 36,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: 92,
                    color: trophyColor,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 3. Challenge Preview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF14181F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.emoji_events_rounded,
                              size: 16,
                              color: trophyColor,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Challenge',
                              style: TextStyle(
                                color: Color(0xFF4FD0F8),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Day 1 of 7',
                          style: TextStyle(
                            color: Color(0xFF7D858E),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_formatNum(_goalSteps)} steps for $_durationDays days',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: days.map((d) {
                        return Expanded(
                          child: Column(
                            children: [
                              Text(
                                d,
                                style: const TextStyle(
                                  color: Color(0xFF7D858E),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 26,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF282E38),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Challenge Preview',
                  style: TextStyle(color: Color(0xFF7D858E), fontSize: 12),
                ),
              ),

              const SizedBox(height: 14),

              // 4. Challenge Type & Goal Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF14181F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _selectFromList(
                        title: 'Challenge Type',
                        options: _challengeTypes,
                        currentValue: _challengeType,
                        onSelected: (val) =>
                            setState(() => _challengeType = val),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Challenge Type',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  _challengeType,
                                  style: const TextStyle(
                                    color: Color(0xFF4FD0F8),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF4FD0F8),
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF222832)),
                    InkWell(
                      onTap: _pickGoal,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Goal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${_formatNum(_goalSteps)} steps / day',
                                  style: const TextStyle(
                                    color: Color(0xFF4FD0F8),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF4FD0F8),
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'All users who hit the daily steps goal win.',
                  style: TextStyle(color: Color(0xFF7D858E), fontSize: 12),
                ),
              ),

              const SizedBox(height: 14),

              // 5. Duration Card
              InkWell(
                onTap: _pickDuration,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14181F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Duration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '$_durationDays days',
                            style: const TextStyle(
                              color: Color(0xFF4FD0F8),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF4FD0F8),
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Challenge will start immediately. Select custom duration to change start date.',
                  style: TextStyle(color: Color(0xFF7D858E), fontSize: 12),
                ),
              ),

              const SizedBox(height: 14),

              // 6. Customize Row
              InkWell(
                onTap: _openCustomizeSheet,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14181F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.brush_rounded,
                        color: Color(0xFF4FD0F8),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Customize',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Color(0xFF8E99A6),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 7. Public & Discoverable Toggle
              _SwitchSettingTile(
                title: 'Public & Discoverable',
                subtitle:
                    'Anyone can discover this challenge in search and recommendations.',
                value: _isPublic,
                onChanged: (val) => setState(() => _isPublic = val),
              ),

              const SizedBox(height: 14),

              // 8. Who can chat Selector
              InkWell(
                onTap: () => _selectFromList(
                  title: 'Who can chat',
                  options: _chatOptions,
                  currentValue: _whoCanChat,
                  onSelected: (val) => setState(() => _whoCanChat = val),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14181F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Who can chat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _whoCanChat,
                            style: const TextStyle(
                              color: Color(0xFF4FD0F8),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF4FD0F8),
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'All participants can chat in the chat.',
                  style: TextStyle(color: Color(0xFF7D858E), fontSize: 12),
                ),
              ),

              const SizedBox(height: 14),

              // 9. Recurring Challenge Toggle
              _SwitchSettingTile(
                title: 'Recurring Challenge',
                subtitle:
                    'Recurring challenges restart automatically with the same participants and settings.',
                value: _isRecurring,
                onChanged: (val) => setState(() => _isRecurring = val),
              ),

              const SizedBox(height: 14),

              // 10. Team Mode Toggle
              _SwitchSettingTile(
                title: 'Team Mode',
                subtitle:
                    'Allow participants to form teams within a challenge and compete as a group. Some challenge goal types cannot be used with Team Mode.',
                value: _isTeamMode,
                onChanged: (val) => setState(() => _isTeamMode = val),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchSettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSettingTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF14181F),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF4FD0F8),
                inactiveThumbColor: const Color(0xFF9AA5B1),
                inactiveTrackColor: const Color(0xFF2B323D),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF7D858E), fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// Second Screen: Active Challenge View + Three-Dots (⋮) Menu (Third Image)
class ChallengeDetailScreen extends StatefulWidget {
  final StepTrackChallengeModel challenge;
  final VoidCallback? onUpdated;

  const ChallengeDetailScreen({
    super.key,
    required this.challenge,
    this.onUpdated,
  });

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final AuthService _authService = AuthService();
  late StepTrackChallengeModel _challenge;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _challenge = widget.challenge;
  }

  String _formatNum(int n) {
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

  String _formatShortDate(DateTime d) {
    const months = [
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
    return '${d.day}. ${months[d.month - 1]}';
  }

  Future<void> _persistChallengeChange(
    StepTrackChallengeModel updated, {
    bool deleted = false,
  }) async {
    final list = ChallengeStorageHelper.loadChallenges();
    final idx = list.indexWhere((c) => c.id == updated.id);
    final next = List<StepTrackChallengeModel>.from(list);

    if (deleted) {
      if (idx >= 0) next.removeAt(idx);
    } else {
      if (idx >= 0) {
        next[idx] = updated;
      } else {
        next.add(updated);
      }
    }

    await ChallengeStorageHelper.saveChallenges(
      next,
      uid: _authService.currentUser?.uid,
    );
    widget.onUpdated?.call();
  }

  Future<void> _copyInviteLink() async {
    await Clipboard.setData(ClipboardData(text: _challenge.inviteLink));
    if (!mounted) return;
    Get.snackbar(
      'Invite Link Copied',
      _challenge.inviteLink,
      backgroundColor: const Color(0xFF132632),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _shareChallenge() async {
    unawaited(
      SharePlus.instance.share(
        ShareParams(
          text:
              'Join "${_challenge.title}" (${_formatNum(_challenge.dailyGoalSteps)} steps for ${_challenge.durationDays} days): ${_challenge.inviteLink}',
        ),
      ),
    );
  }

  Future<void> _addFriendDialog() async {
    final ctrl = TextEditingController();
    await Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF141920),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Friends to Challenge',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Friend name or email',
            hintStyle: const TextStyle(color: Color(0xFF7D858E)),
            filled: true,
            fillColor: const Color(0xFF0C1015),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8E99A6)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final friend = ctrl.text.trim();
              if (friend.isNotEmpty) {
                final updatedParticipants =
                    List<String>.from(_challenge.participants)..add(friend);
                final updated =
                    _challenge.copyWith(participants: updatedParticipants);
                setState(() => _challenge = updated);
                await _persistChallengeChange(updated);

                final existingInvites = _authService.getCachedInvitedFriends();
                await _authService.saveInvitedFriends(
                  [...existingInvites, friend],
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FD0F8),
              foregroundColor: const Color(0xFF081016),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleHideInHomeTab() async {
    final updated =
        _challenge.copyWith(hiddenInHomeTab: !_challenge.hiddenInHomeTab);
    setState(() => _challenge = updated);
    await _persistChallengeChange(updated);
    if (!mounted) return;
    Get.snackbar(
      updated.hiddenInHomeTab ? 'Hidden in Home Tab' : 'Shown in Home Tab',
      updated.hiddenInHomeTab
          ? 'Challenge Home tab se hide kar diya gaya hai.'
          : 'Challenge Home tab mein wapas show hoga.',
      backgroundColor: const Color(0xFF132632),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _openCustomizeFromMenu() async {
    final result = await Get.to<StepTrackChallengeModel>(
      () => CreateChallengeScreen(
        initialChallenge: _challenge,
        onChallengeSaved: () => widget.onUpdated?.call(),
      ),
    );
    if (result != null && mounted) {
      setState(() => _challenge = result);
    } else if (mounted) {
      final refreshed = ChallengeStorageHelper.loadChallenges()
          .where((c) => c.id == _challenge.id)
          .toList();
      if (refreshed.isNotEmpty) {
        setState(() => _challenge = refreshed.first);
      }
    }
  }

  Future<void> _openChallengeSettingsDialog() async {
    bool publicVal = _challenge.isPublic;
    bool recurringVal = _challenge.isRecurring;
    bool teamVal = _challenge.isTeamMode;

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF141920),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Challenge Settings',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  value: publicVal,
                  activeColor: const Color(0xFF4FD0F8),
                  title: const Text(
                    'Public & Discoverable',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  onChanged: (v) => setDialogState(() => publicVal = v),
                ),
                SwitchListTile(
                  value: recurringVal,
                  activeColor: const Color(0xFF4FD0F8),
                  title: const Text(
                    'Recurring Challenge',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  onChanged: (v) => setDialogState(() => recurringVal = v),
                ),
                SwitchListTile(
                  value: teamVal,
                  activeColor: const Color(0xFF4FD0F8),
                  title: const Text(
                    'Team Mode',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  onChanged: (v) => setDialogState(() => teamVal = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF8E99A6)),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final updated = _challenge.copyWith(
                    isPublic: publicVal,
                    isRecurring: recurringVal,
                    isTeamMode: teamVal,
                  );
                  setState(() => _challenge = updated);
                  await _persistChallengeChange(updated);
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FD0F8),
                  foregroundColor: const Color(0xFF081016),
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportCsv() async {
    final csvData =
        'id,title,type,goal_steps,duration_days,participants\n'
        '"${_challenge.id}","${_challenge.title}","${_challenge.challengeType}",'
        '${_challenge.dailyGoalSteps},${_challenge.durationDays},'
        '"${_challenge.participants.join(';')}"';

    await Clipboard.setData(ClipboardData(text: csvData));
    if (!mounted) return;
    Get.snackbar(
      'CSV Exported',
      'Challenge CSV data clipboard mein copy ho gaya hai.',
      backgroundColor: const Color(0xFF132632),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _manageParticipantsDialog() async {
    await Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF141920),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Manage Participants',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _challenge.participants.length,
            itemBuilder: (_, idx) {
              final member = _challenge.participants[idx];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  member,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: idx == 0
                    ? const Text(
                        'Host',
                        style: TextStyle(color: Color(0xFF4FD0F8)),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Color(0xFFFF5252),
                        ),
                        onPressed: () async {
                          final nextMembers =
                              List<String>.from(_challenge.participants)
                                ..removeAt(idx);
                          final updated = _challenge.copyWith(
                            participants: nextMembers,
                          );
                          setState(() => _challenge = updated);
                          await _persistChallengeChange(updated);
                          Get.back();
                        },
                      ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Done',
              style: TextStyle(color: Color(0xFF4FD0F8)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChallenge() async {
    await _persistChallengeChange(_challenge, deleted: true);
    if (!mounted) return;
    Get.back(result: _challenge);
    Get.snackbar(
      'Challenge Deleted',
      '"${_challenge.title}" delete ho gaya hai.',
      backgroundColor: const Color(0xFF2A1418),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color trophyColor = Color(_challenge.accentColorValue);
    final String rangeText =
        '${_formatShortDate(_challenge.startDate)} – ${_formatShortDate(_challenge.endDate)}';
    final dayLetters = List.generate(
      _challenge.durationDays.clamp(1, 7),
      (i) => ['W', 'T', 'F', 'S', 'S', 'M', 'T'][i % 7],
    );

    return Scaffold(
      backgroundColor: const Color(0xFF05080A),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Bar: Close (X) + Chat Icon + Three Dots (⋮)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Get.back(result: _challenge),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 26,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Get.snackbar(
                              'Challenge Chat',
                              '${_challenge.title} chat (${_challenge.whoCanChat}).',
                              backgroundColor: const Color(0xFF132632),
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                            ),
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.white70,
                              size: 22,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => _isMenuOpen = !_isMenuOpen),
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Trophy + Title + Date Range Pill
                  Center(
                    child: Icon(
                      Icons.emoji_events_rounded,
                      size: 96,
                      color: trophyColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _challenge.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: Color(0xFF9AA5B1),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            rangeText,
                            style: const TextStyle(
                              color: Color(0xFF9AA5B1),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Challenge Progress Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14181F),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.emoji_events_rounded,
                                  size: 16,
                                  color: trophyColor,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Challenge',
                                  style: TextStyle(
                                    color: Color(0xFF4FD0F8),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Day 1 of ${_challenge.durationDays}',
                              style: const TextStyle(
                                color: Color(0xFF7D858E),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${_formatNum(_challenge.dailyGoalSteps)} steps for ${_challenge.durationDays} days',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(dayLetters.length, (i) {
                            final done = _challenge.completedDayIndices.contains(i);
                            return Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    dayLetters[i],
                                    style: const TextStyle(
                                      color: Color(0xFF7D858E),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 26,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: done
                                          ? const Color(0xFF4FD0F8)
                                          : const Color(0xFF282E38),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Invite Friends with Link Section
                  const Text(
                    'Invite friends with link',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _addFriendDialog,
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text(
                        'Invite Friends',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1F27),
                        foregroundColor: const Color(0xFF4FD0F8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: _copyInviteLink,
                    icon: const Icon(
                      Icons.link_rounded,
                      color: Color(0xFF4FD0F8),
                      size: 18,
                    ),
                    label: const Text(
                      'Copy Invite Link',
                      style: TextStyle(
                        color: Color(0xFF4FD0F8),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Text(
                    'Share a link for participants. Anyone with access to the link can join the challenge.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF7D858E),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            // Three-Dots (⋮) Popup Menu Overlay (Third Image)
            if (_isMenuOpen) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _isMenuOpen = false),
                  child: Container(color: Colors.black26),
                ),
              ),
              Positioned(
                top: 52,
                right: 16,
                child: Material(
                  color: const Color(0xFF181C22),
                  elevation: 12,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 245,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181C22),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF262D38)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _popupItem(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          onTap: () async {
                            setState(() => _isMenuOpen = false);
                            await _shareChallenge();
                          },
                        ),
                        _popupItem(
                          icon: Icons.link_rounded,
                          label: 'Copy Invite Link',
                          onTap: () async {
                            setState(() => _isMenuOpen = false);
                            await _copyInviteLink();
                          },
                        ),
                        _popupItem(
                          icon: Icons.person_add_alt_1_outlined,
                          label: 'Add Friends',
                          onTap: () async {
                            setState(() => _isMenuOpen = false);
                            await _addFriendDialog();
                          },
                        ),
                        const Divider(height: 8, color: Color(0xFF262D38)),
                        _popupItem(
                          icon: Icons.home_outlined,
                          label: 'Hide in Home Tab',
                          onTap: () async {
                            setState(() => _isMenuOpen = false);
                            await _toggleHideInHomeTab();
                          },
                        ),
                        _popupItem(
                          icon: Icons.brush_rounded,
                          label: 'Customize',
                          onTap: () async {
                            setState(() => _isMenuOpen = false);
                            await _openCustomizeFromMenu();
                          },
                        ),
                        _popupItem(
                          icon: Icons.tune_rounded,
                          label: 'Challenge Settings',
                          onTap: () async {
                            setState(() => _isMenuOpen = false);
                            await _openChallengeSettingsDialog();
                          },
                        ),
                        const Divider(height: 8, color: Color(0xFF262D38)),
                        _popupItem(
                          icon: Icons.file_upload_outlined,
                          label: 'CSV Export',
                          onTap: () async {
                            setState(() => _isMenuOpen = false);
                            await _exportCsv();
                          },
                        ),
                        _popupItem(
                          icon: Icons.group_outlined,
                          label: 'Manage Participants',
                          onTap: () async {
                            setState(() => _isMenuOpen = false);
                            await _manageParticipantsDialog();
                          },
                        ),
                        const Divider(height: 8, color: Color(0xFF262D38)),
                        _popupItem(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete Challenge',
                          color: const Color(0xFFFF5252),
                          onTap: () async {
                            setState(() => _isMenuOpen = false);
                            await _deleteChallenge();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _popupItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14.5,
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
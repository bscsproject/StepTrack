import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:step_track/services/auth_service.dart';

class StepTrackGroupModel {
  final String id;
  final String name;
  final String emoji;
  final int avatarColorValue;
  final bool isPublic;
  final String createdAt;

  const StepTrackGroupModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.avatarColorValue,
    required this.isPublic,
    required this.createdAt,
  });

  String get initial =>
      name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'G';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'avatarColorValue': avatarColorValue,
      'isPublic': isPublic,
      'createdAt': createdAt,
    };
  }

  factory StepTrackGroupModel.fromMap(Map<String, dynamic> map) {
    return StepTrackGroupModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      emoji: map['emoji']?.toString() ?? '',
      avatarColorValue: int.tryParse(map['avatarColorValue']?.toString() ?? '') ??
          0xFFB39DDB,
      isPublic: map['isPublic'] == true,
      createdAt: map['createdAt']?.toString() ?? '',
    );
  }
}

class CreateGroupScreen extends StatefulWidget {
  final ValueChanged<StepTrackGroupModel>? onGroupCreated;

  const CreateGroupScreen({
    super.key,
    this.onGroupCreated,
  });

  static const String boxName = 'steptrack_auth_box';
  static const String groupsKey = 'user_groups_list_json';

  static List<StepTrackGroupModel> loadCachedGroups() {
    if (!Hive.isBoxOpen(boxName)) return const [];
    final box = Hive.box(boxName);
    final raw = box.get(groupsKey);
    if (raw == null || raw.toString().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw.toString());
      if (decoded is List) {
        return decoded
            .whereType()
            .map((e) => StepTrackGroupModel.fromMap(Map<String, dynamic>.from(e)))
            .where((g) => g.name.trim().isNotEmpty)
            .toList();
      }
    } catch (error, stackTrace) {
      debugPrint('Could not decode cached groups: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    return const [];
  }

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emojiController = TextEditingController();

  final List<Color> _swatches = const [
    Color(0xFF1DE9B6), // Mint Teal
    Color(0xFF00B0FF), // Sky Blue
    Color(0xFF2979FF), // Royal Blue
    Color(0xFF651FFF), // Indigo Purple
    Color(0xFFB39DDB), // Soft Lavender
    Color(0xFFFF4081), // Hot Pink
    Color(0xFFFF5252), // Coral Red
  ];

  int _selectedSwatchIndex = 4;
  bool _isPublic = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  void _shuffleColor() {
    setState(() {
      _selectedSwatchIndex = (_selectedSwatchIndex + 1) % _swatches.length;
    });
  }

  Future<void> _createGroup() async {
    final cleanName = _nameController.text.trim();
    if (cleanName.isEmpty) {
      Get.snackbar(
        'Group Name Required',
        'Please enter a group name first.',
        backgroundColor: const Color(0xFF1B2430),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final chosenColor = _swatches[_selectedSwatchIndex];
      final now = DateTime.now();
      final group = StepTrackGroupModel(
        id: 'grp_${now.millisecondsSinceEpoch}',
        name: cleanName,
        emoji: _emojiController.text.trim(),
        avatarColorValue: chosenColor.value,
        isPublic: _isPublic,
        createdAt: now.toIso8601String(),
      );

      final existing = CreateGroupScreen.loadCachedGroups();
      final updatedList = [...existing, group];

      if (!Hive.isBoxOpen(CreateGroupScreen.boxName)) {
        throw StateError(
          'Hive box "${CreateGroupScreen.boxName}" is not open.',
        );
      }
      final box = Hive.box(CreateGroupScreen.boxName);
      await box.put(
        CreateGroupScreen.groupsKey,
        jsonEncode(updatedList.map((e) => e.toMap()).toList()),
      );

      final uid = _authService.currentUser?.uid;
      var cloudSyncFailed = false;
      if (uid != null) {
        try {
          await _firestore.collection('users').doc(uid).set({
            'groups': updatedList.map((e) => e.toMap()).toList(),
            'activeGroupId': group.id,
          }, SetOptions(merge: true));
        } catch (error, stackTrace) {
          cloudSyncFailed = true;
          debugPrint('Could not sync the new group to Firestore: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }

      widget.onGroupCreated?.call(group);

      if (!mounted) return;
      Get.back(result: group);
      Get.snackbar(
        cloudSyncFailed ? 'Group saved locally' : 'Group Created',
        cloudSyncFailed
            ? '"${group.name}" is on this device but could not sync to your account.'
            : '"${group.name}" group created and added to Home.',
        backgroundColor: const Color(0xFF132632),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = _swatches[_selectedSwatchIndex];
    final String previewText = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()[0].toUpperCase()
        : 'C';

    return Scaffold(
      backgroundColor: const Color(0xFF06080A),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar: Cancel | Create Group | Create
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF4FD0F8),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Text(
                    'Create Group',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isSaving ? null : _createGroup,
                    child: Text(
                      'Create',
                      style: TextStyle(
                        color: _isSaving
                            ? const Color(0xFF3E6B7B)
                            : const Color(0xFF4FD0F8),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 34),

              // Large Circular Group Avatar with Ring
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activeColor.withValues(alpha: 0.75),
                      width: 3,
                    ),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      previewText,
                      style: const TextStyle(
                        color: Color(0xFF0A0D10),
                        fontSize: 64,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),
              const Text(
                'Edit Avatar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),

              // Shuffle + Color Swatches Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _shuffleColor,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.shuffle_rounded,
                        color: Color(0xFFB39DDB),
                        size: 17,
                      ),
                    ),
                  ),
                  ...List.generate(_swatches.length, (index) {
                    final color = _swatches[index];
                    final bool selected = index == _selectedSwatchIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSwatchIndex = index),
                      child: Container(
                        width: selected ? 32 : 28,
                        height: selected ? 32 : 28,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                        ),
                      ),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 28),

              // Group Name & Optional Emoji Input Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF15181E),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: TextField(
                        controller: _nameController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          color: Color(0xFF4FD0F8),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        cursorColor: const Color(0xFF4FD0F8),
                        decoration: const InputDecoration(
                          hintText: 'Group name (e.g. Coder)',
                          hintStyle: TextStyle(color: Color(0xFF6B7480)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF232832)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: TextField(
                        controller: _emojiController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Emoji / tagline (optional)',
                          hintStyle: TextStyle(
                            color: Color(0xFF6B7480),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Public & Discoverable Toggle Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF15181E),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Public & Discoverable',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Switch(
                      value: _isPublic,
                      onChanged: (val) => setState(() => _isPublic = val),
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF00B0FF),
                      inactiveThumbColor: const Color(0xFF9AA5B1),
                      inactiveTrackColor: const Color(0xFF2B323D),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Anyone can discover this group in search and recommendations.',
                  style: TextStyle(
                    color: Color(0xFF7D858E),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
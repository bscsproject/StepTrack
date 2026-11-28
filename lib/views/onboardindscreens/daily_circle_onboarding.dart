import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/auth_service.dart';

class DailyCircleOnboardingScreen extends StatefulWidget {
  final int totalSteps;
  final int currentStep;
  final VoidCallback? onGetStarted;
  final VoidCallback? onSkip;

  const DailyCircleOnboardingScreen({
    super.key,
    this.totalSteps = 8,
    this.currentStep = 4,
    this.onGetStarted,
    this.onSkip,
  });

  @override
  State<DailyCircleOnboardingScreen> createState() =>
      _DailyCircleOnboardingScreenState();
}

class _DailyCircleOnboardingScreenState
    extends State<DailyCircleOnboardingScreen> {
  final AuthService _authService = AuthService();

  final List<_FriendInviteItem> _friends = const [
    _FriendInviteItem(
      id: 'friend_1',
      name: 'Friend 1',
      subtitle: 'Add them to your daily walking feed',
      avatarBg: Color(0xFFF6C2C7),
      badgeColor: Color(0xFF19A7E6),
      emoji: '😂',
    ),
    _FriendInviteItem(
      id: 'friend_2',
      name: 'Friend 2',
      subtitle: 'Add them to your daily walking feed',
      avatarBg: Color(0xFFB9E8A2),
      badgeColor: Color(0xFF19A7E6),
      emoji: '😜',
    ),
    _FriendInviteItem(
      id: 'friend_3',
      name: 'Friend 3',
      subtitle: 'Add them to your daily walking feed',
      avatarBg: Color(0xFFE5B3F0),
      badgeColor: Color(0xFF19A7E6),
      emoji: '😊',
    ),
  ];

  final Set<String> _invitedIds = <String>{};
  String _userInitial = 'L';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  void _loadInitialState() {
    final cachedUser = _authService.getCachedUser();
    final name = cachedUser?.name.trim() ?? '';
    if (name.isNotEmpty) {
      _userInitial = name[0].toUpperCase();
    }

    final savedInvites = _authService.getCachedInvitedFriends();
    setState(() {
      _invitedIds
        ..clear()
        ..addAll(savedInvites);
    });
  }

  Future<void> _toggleInvite(_FriendInviteItem friend) async {
    final bool alreadyInvited = _invitedIds.contains(friend.id);

    setState(() {
      if (alreadyInvited) {
        _invitedIds.remove(friend.id);
      } else {
        _invitedIds.add(friend.id);
      }
    });

    try {
      await _authService.saveInvitedFriends(
        _invitedIds.toList(),
        awaitCloudSync: false,
      );

      if (!alreadyInvited) {
        const inviteCode = 'STEPTRACK-CIRCLE';
        await Clipboard.setData(const ClipboardData(text: inviteCode));

        unawaited(
          SharePlus.instance
              .share(
                ShareParams(
                  text:
                      'Join my Daily Circle on StepTrack! Use invite code: $inviteCode',
                ),
              )
              .catchError((e) {
                debugPrint('Share error: $e');
                return ShareResult('', ShareResultStatus.unavailable);
              }),
        );

        if (!mounted) return;
        Get.snackbar(
          'Invite Sent',
          '${friend.name} ko invite add kar diya gaya hai (Code:$inviteCode copied).',
          backgroundColor: const Color(0xFF15222B),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        if (!mounted) return;
        Get.snackbar(
          'Invite Removed',
          '${friend.name} ko invite list se hata diya gaya hai.',
          backgroundColor: const Color(0xFF15222B),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint('Toggle invite error: $e');
      if (mounted) {
        Get.snackbar(
          'Update Failed',
          'Invite update karte waqt masla aaya.',
          backgroundColor: const Color(0xFF28181D),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _onGetStartedPressed() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await _authService.saveInvitedFriends(
        _invitedIds.toList(),
        awaitCloudSync: false,
      );
      await _authService.saveWelcomePreferences(
        subscribeNewsletter:
            _authService.getCachedUser()?.subscribeNewsletter ?? true,
        isOnboardingCompleted: false,
        awaitCloudSync: false,
      );

      if (!mounted) return;
      if (widget.onGetStarted != null) {
        widget.onGetStarted!();
      } else {
        Get.snackbar(
          'All Set!',
          'Aapka Daily Circle aur onboarding setup save ho gaya hai.',
          backgroundColor: const Color(0xFF15222B),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Daily circle save error: $e');
      if (mounted) {
        Get.snackbar(
          'Save Failed',
          'Setup save karte waqt masla aaya. Dobara koshish karein.',
          backgroundColor: const Color(0xFF28181D),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _onSkipPressed() {
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else if (widget.onGetStarted != null) {
      widget.onGetStarted!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int safeTotal = widget.totalSteps > 0 ? widget.totalSteps : 8;
    final int safeStep = widget.currentStep.clamp(0, safeTotal - 1);

    return Scaffold(
      backgroundColor: const Color(0xFF080A0C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          child: Column(
            children: [
              // 1. Top Segmented Progress Bars + Right Skip Button
              Row(
                children: [
                  const SizedBox(width: 44),
                  Expanded(
                    child: Row(
                      children: List.generate(safeTotal, (index) {
                        final bool isActive = index <= safeStep;
                        return Expanded(
                          child: Container(
                            height: 4.5,
                            margin: EdgeInsets.only(
                              right: index == safeTotal - 1 ? 0 : 7,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF19A7E6)
                                  : const Color(0xFF1B2026),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _onSkipPressed,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Color(0xFF7D858E),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 2. Daily Circle Preview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF12161B),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Daily Circle',
                            style: TextStyle(
                              color: Color(0xFF4FD0F8),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 96,
                          height: 40,
                          child: Stack(
                            alignment: Alignment.centerRight,
                            children: const [
                              Positioned(
                                right: 52,
                                child: _MiniAvatarCircle(
                                  bg: Color(0xFFF6C2C7),
                                  emoji: '😂',
                                ),
                              ),
                              Positioned(
                                right: 26,
                                child: _MiniAvatarCircle(
                                  bg: Color(0xFFB9E8A2),
                                  emoji: '😜',
                                ),
                              ),
                              Positioned(
                                right: 0,
                                child: _MiniAvatarCircle(
                                  bg: Color(0xFFE5B3F0),
                                  emoji: '😊',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'See Your Friends\nWalk Every Day',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 31,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Inner Step Feed Row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0D10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7C4DFF),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _userInitial,
                              style: const TextStyle(
                                color: Color(0xFF121212),
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14212D),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Text(
                              '96 steps',
                              style: TextStyle(
                                color: Color(0xFF4FD0F8),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Friend Invite Cards (Friend 1, Friend 2, Friend 3)
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _friends.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final friend = _friends[index];
                    final bool isInvited = _invitedIds.contains(friend.id);

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12161B),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 52,
                            height: 50,
                            child: Stack(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: friend.avatarBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    friend.emoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: isInvited
                                          ? const Color(0xFF2ECC71)
                                          : friend.badgeColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF12161B),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      isInvited ? Icons.check : Icons.add,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  friend.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isInvited
                                      ? 'Invite added to daily circle'
                                      : friend.subtitle,
                                  style: const TextStyle(
                                    color: Color(0xFF7D858E),
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _toggleInvite(friend),
                            style: TextButton.styleFrom(
                              foregroundColor: isInvited
                                  ? const Color(0xFF4FD0F8)
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                            ),
                            child: Text(
                              isInvited ? 'Invited' : 'Invite',
                              style: TextStyle(
                                color: isInvited
                                    ? const Color(0xFF4FD0F8)
                                    : Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // 4. Bottom Cyan "Get Started" Pill Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _onGetStartedPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FD0F8),
                    foregroundColor: const Color(0xFF0A1014),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF0A1014),
                          ),
                        )
                      : const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0A1014),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniAvatarCircle extends StatelessWidget {
  final Color bg;
  final String emoji;

  const _MiniAvatarCircle({required this.bg, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF12161B), width: 2),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 18)),
    );
  }
}

class _FriendInviteItem {
  final String id;
  final String name;
  final String subtitle;
  final Color avatarBg;
  final Color badgeColor;
  final String emoji;

  const _FriendInviteItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.avatarBg,
    required this.badgeColor,
    required this.emoji,
  });
}

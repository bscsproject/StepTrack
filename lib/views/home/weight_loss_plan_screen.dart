import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:step_track/services/auth_service.dart';

class WeightLossPlanScreen extends StatefulWidget {
  final int currentGoal;
  final VoidCallback? onPlanActivated;

  const WeightLossPlanScreen({
    super.key,
    this.currentGoal = 6000,
    this.onPlanActivated,
  });

  @override
  State<WeightLossPlanScreen> createState() => _WeightLossPlanScreenState();
}

class _WeightLossPlanScreenState extends State<WeightLossPlanScreen> {
  static const String _boxName = 'steptrack_auth_box';
  static const String _currentUserKey = 'current_user_json';

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 0: 12 Months (default selected), 1: 1 Month
  int _selectedPlanIndex = 0;
  bool _isActivating = false;

  Future<void> _saveSelectedPlanToStorageAndFirestore() async {
    final bool isYearly = _selectedPlanIndex == 0;
    final String planId = isYearly ? 'ultra_12_months' : 'ultra_1_month';
    final String planLabel = isYearly ? '12 Months' : '1 Month';
    final String priceSummary = isYearly
        ? '7 days free, then Rs 11,100.00/year (Rs925.00 / month)'
        : '7 days free, then Rs 2,750.00 / month';

    final int upgradedGoal =
        widget.currentGoal >= 8000 ? widget.currentGoal : 8000;
    await _authService.saveUserMainGoal('$upgradedGoal steps');

    if (Hive.isBoxOpen(_boxName)) {
      final box = Hive.box(_boxName);
      final currentAuthUser = _authService.currentUser;
      final existing = (currentAuthUser != null
              ? _authService.getCachedUserByUid(currentAuthUser.uid)
              : null) ??
          _authService.getCachedUser();

      final uid = currentAuthUser?.uid ?? existing?.uid ?? 'guest_user';
      final Map<String, dynamic> existingMap = existing?.toMap() ?? {};

      final Map<String, dynamic> updatedMap = {
        ...existingMap,
        'uid': uid,
        'name':
            existing?.name ?? currentAuthUser?.displayName ?? 'StepTrack User',
        'email': existing?.email ?? currentAuthUser?.email ?? '',
        'createdAt': existing?.createdAt.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'weightLossPlanActive': true,
        'weightLossPlanId': planId,
        'weightLossPlanLabel': planLabel,
        'weightLossPlanPrice': priceSummary,
        'freeTrialStartedAt': DateTime.now().toIso8601String(),
      };

      await box.put(_currentUserKey, jsonEncode(updatedMap));
      await box.put('user_$uid', jsonEncode(updatedMap));

      if (currentAuthUser != null) {
        try {
          await _firestore.collection('users').doc(currentAuthUser.uid).set({
            'weightLossPlanActive': true,
            'weightLossPlanId': planId,
            'weightLossPlanLabel': planLabel,
            'weightLossPlanPrice': priceSummary,
            'freeTrialStartedAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }
    }
  }

  Future<void> _onStartFreeTrialPressed() async {
    if (_isActivating) return;
    setState(() => _isActivating = true);

    try {
      await _saveSelectedPlanToStorageAndFirestore();
      widget.onPlanActivated?.call();

      if (!mounted) return;
      final planText =
          _selectedPlanIndex == 0 ? '12 Months ULTRA' : '1 Month ULTRA';
      Get.back();
      Get.snackbar(
        'Free Trial Activated',
        '$planText weight loss plan start ho gaya hai.',
        backgroundColor: const Color(0xFF132632),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isActivating = false);
      }
    }
  }

  void _showLegalInfo(String title, String bodyText) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF141920),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          bodyText,
          style: const TextStyle(color: Color(0xFF9AA5B1), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF4FD0F8)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String subtitlePrice = _selectedPlanIndex == 0
        ? '7 days free, then Rs 11,100.00/year'
        : '7 days free, then Rs 2,750.00/month';

    return Scaffold(
      backgroundColor: const Color(0xFF050709),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top Transformation Banner + Close (X) + ULTRA Badge
                  SizedBox(
                    height: 270,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF2B2A29),
                                      Color(0xFF171615),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.accessibility_new_rounded,
                                  size: 130,
                                  color: Color(0xFF6B655F),
                                ),
                              ),
                            ),
                            Container(width: 1.5, color: Colors.white30),
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF3A3530),
                                      Color(0xFF181615),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.directions_run_rounded,
                                  size: 130,
                                  color: Color(0xFF8C8278),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Bottom fade into dark background
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 85,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Color(0xFF050709),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Top-left Close (X)
                        SafeArea(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              onPressed: () => Get.back(),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                        // ULTRA Purple Pill Badge
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8A2BE2),
                                    Color(0xFF9C42F5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'ULTRA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 2. Title & Trial Price Subtitle
                  const Text(
                    'Start your\npersonalized plan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitlePrice,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF8E99A6),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Card 1: WHAT YOU WILL GET
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _FeatureGroupCard(
                      header: 'WHAT YOU WILL GET',
                      items: const [
                        _FeatureItemData(
                          icon: Icons.calendar_today_rounded,
                          iconColor: Color(0xFF4FD0F8),
                          title: 'Calculated goal timeline',
                        ),
                        _FeatureItemData(
                          icon: Icons.monitor_weight_outlined,
                          iconColor: Color(0xFF35D41B),
                          title: 'Weekly weigh-ins',
                        ),
                        _FeatureItemData(
                          icon: Icons.directions_walk_rounded,
                          iconColor: Color(0xFF9C42F5),
                          title: 'Adaptive step goals',
                        ),
                        _FeatureItemData(
                          icon: Icons.fitness_center_rounded,
                          iconColor: Color(0xFFFFB300),
                          title: 'Guided workouts',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 4. Card 2: WHAT YOU WILL ALSO GET
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _FeatureGroupCard(
                      header: 'WHAT YOU WILL ALSO GET',
                      items: const [
                        _FeatureItemData(
                          icon: Icons.bar_chart_rounded,
                          iconColor: Color(0xFFFF5252),
                          title: 'Extended Insights',
                        ),
                        _FeatureItemData(
                          icon: Icons.block_flipped,
                          iconColor: Color(0xFFFFB300),
                          title: '100% Ad-Free',
                        ),
                        _FeatureItemData(
                          icon: Icons.track_changes_rounded,
                          iconColor: Color(0xFF9C42F5),
                          title: 'Advanced Goals',
                        ),
                        _FeatureItemData(
                          icon: Icons.palette_outlined,
                          iconColor: Color(0xFFFF4DA6),
                          title: 'Custom Colors and App Icons',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 5. Card 3: SELECT YOUR PLAN
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10151C),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1A232F)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SELECT YOUR PLAN',
                            style: TextStyle(
                              color: Color(0xFF7D858E),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 12 Months Option
                          GestureDetector(
                            onTap: () => setState(() => _selectedPlanIndex = 0),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedPlanIndex == 0
                                        ? const Color(0xFF0D212C)
                                        : const Color(0xFF161C24),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _selectedPlanIndex == 0
                                          ? const Color(0xFF4FD0F8)
                                          : const Color(0xFF232C38),
                                      width: 1.6,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '12 Months',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          RichText(
                                            text: const TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: 'Rs 11,100.00  ',
                                                  style: TextStyle(
                                                    color: Color(0xFF7D858E),
                                                    fontSize: 12,
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: 'SAVE 66%',
                                                  style: TextStyle(
                                                    color: Color(0xFF4FD0F8),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Text(
                                        'Rs925.00 / month',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_selectedPlanIndex == 0)
                                  Positioned(
                                    top: -8,
                                    right: -6,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4FD0F8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Color(0xFF081016),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // 1 Month Option
                          GestureDetector(
                            onTap: () => setState(() => _selectedPlanIndex = 1),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedPlanIndex == 1
                                        ? const Color(0xFF0D212C)
                                        : const Color(0xFF161C24),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _selectedPlanIndex == 1
                                          ? const Color(0xFF4FD0F8)
                                          : const Color(0xFF232C38),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '1 Month',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Rs 2,750.00 / month',
                                        style: TextStyle(
                                          color: Color(0xFFB7C2CE),
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_selectedPlanIndex == 1)
                                  Positioned(
                                    top: -8,
                                    right: -6,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4FD0F8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Color(0xFF081016),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 6. Card 4: Social Proof & Rating + Legal Links
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10151C),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1A232F)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              _AvatarBadge(
                                color: Color(0xFF4FD0F8),
                                icon: Icons.face_3,
                              ),
                              _AvatarBadge(
                                color: Color(0xFF8D6E63),
                                icon: Icons.face_6,
                              ),
                              _AvatarBadge(
                                color: Color(0xFFFF8A65),
                                icon: Icons.sentiment_satisfied_alt,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Trusted by 10+ million walkers',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.workspace_premium_outlined,
                                color: Color(0xFF8E99A6),
                                size: 26,
                              ),
                              SizedBox(width: 8),
                              Column(
                                children: [
                                  Text(
                                    '4.8',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.star, color: Color(0xFFFFC107), size: 13),
                                      Icon(Icons.star, color: Color(0xFFFFC107), size: 13),
                                      Icon(Icons.star, color: Color(0xFFFFC107), size: 13),
                                      Icon(Icons.star, color: Color(0xFFFFC107), size: 13),
                                      Icon(Icons.star_half, color: Color(0xFFFFC107), size: 13),
                                    ],
                                  ),
                                  Text(
                                    '2 million ratings',
                                    style: TextStyle(
                                      color: Color(0xFF7D858E),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.workspace_premium_outlined,
                                color: Color(0xFF8E99A6),
                                size: 26,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => _showLegalInfo(
                                  'Privacy Policy',
                                  'Aapka fitness, weight aur goal data sirf aapke account aur local cache ke mutabiq sync hota hai.',
                                ),
                                child: const Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    color: Color(0xFF8E99A6),
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const Text(
                                ' · ',
                                style: TextStyle(color: Color(0xFF7D858E)),
                              ),
                              GestureDetector(
                                onTap: () => _showLegalInfo(
                                  'Terms of Service',
                                  '7-day free trial ke baad selected plan apply hota hai aur aap kisi bhi waqt cancel kar sakte hain.',
                                ),
                                child: const Text(
                                  'Terms of Service',
                                  style: TextStyle(
                                    color: Color(0xFF8E99A6),
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
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
          ),

          // 7. Sticky Bottom CTA Button + Cancel Anytime
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: const BoxDecoration(
              color: Color(0xFF050709),
              border: Border(
                top: BorderSide(color: Color(0xFF151D26), width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isActivating ? null : _onStartFreeTrialPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FD0F8),
                        foregroundColor: const Color(0xFF081016),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _isActivating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF081016),
                              ),
                            )
                          : const Text(
                              'Start my free trial',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cancel anytime · No commitment',
                    style: TextStyle(
                      color: Color(0xFF7D858E),
                      fontSize: 12,
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
}

class _FeatureItemData {
  final IconData icon;
  final Color iconColor;
  final String title;

  const _FeatureItemData({
    required this.icon,
    required this.iconColor,
    required this.title,
  });
}

class _FeatureGroupCard extends StatelessWidget {
  final String header;
  final List<_FeatureItemData> items;

  const _FeatureGroupCard({
    required this.header,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10151C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A232F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: const TextStyle(
              color: Color(0xFF7D858E),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(items.length, (index) {
            final item = items[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == items.length - 1 ? 0 : 14,
              ),
              child: Row(
                children: [
                  Icon(item.icon, color: item.iconColor, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _AvatarBadge({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF10151C), width: 2),
      ),
      child: Icon(icon, color: const Color(0xFF0A1014), size: 24),
    );
  }
}
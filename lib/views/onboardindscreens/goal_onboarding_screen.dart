import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';

class GoalOnboardingScreen extends StatefulWidget {
  final int totalSteps;
  final int currentStep;
  final VoidCallback? onContinue;

  const GoalOnboardingScreen({
    super.key,
    this.totalSteps = 9,
    this.currentStep = 2,
    this.onContinue,
  });

  @override
  State<GoalOnboardingScreen> createState() => _GoalOnboardingScreenState();
}

class _GoalOnboardingScreenState extends State<GoalOnboardingScreen> {
  final AuthService _authService = AuthService();

  final List<_GoalOption> _goals = const [
    _GoalOption(
      title: 'Track my steps',
      icon: Icons.directions_walk,
      iconColor: Color(0xFF29B6F6),
    ),
    _GoalOption(
      title: 'Lose weight',
      icon: Icons.scale,
      iconColor: Color(0xFF90A4AE),
    ),
    _GoalOption(
      title: 'Walk more',
      icon: Icons.emoji_events,
      iconColor: Color(0xFFFFCA28),
    ),
    _GoalOption(
      title: 'Train for a run',
      icon: Icons.directions_run,
      iconColor: Color(0xFFFFB74D),
    ),
    _GoalOption(
      title: 'Improve overall health',
      icon: Icons.favorite,
      iconColor: Color(0xFFE53935),
    ),
    _GoalOption(
      title: 'Get active with friends',
      icon: Icons.group,
      iconColor: Color(0xFF00B0FF),
    ),
    _GoalOption(
      title: 'Something else',
      icon: Icons.track_changes,
      iconColor: Color(0xFFFF5252),
    ),
  ];

  String _selectedGoal = 'Track my steps';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final savedGoal = _authService.getCachedMainGoal();
    if (savedGoal != null && _goals.any((g) => g.title == savedGoal)) {
      _selectedGoal = savedGoal;
    }
  }

  Future<void> _onContinuePressed() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await _authService.saveUserMainGoal(_selectedGoal);

      if (widget.onContinue != null) {
        widget.onContinue!();
      } else {
        Get.snackbar(
          'Goal Saved',
          'Main goal "$_selectedGoal" save ho gaya hai.',
          backgroundColor: const Color(0xFF15222B),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080A0C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 18.0),
          child: Column(
            children: [
              // 1. Top Segmented Onboarding Progress Bars (3rd bar active)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Row(
                  children: List.generate(widget.totalSteps, (index) {
                    final bool isActive = index == widget.currentStep;
                    return Expanded(
                      child: Container(
                        height: 4.5,
                        margin: EdgeInsets.only(
                          right: index == widget.totalSteps - 1 ? 0 : 8,
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

              const SizedBox(height: 28),

              // 2. Title
              const Text(
                "What's your main goal?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 24),

              // 3. Goal Option Pills
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _goals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = _goals[index];
                    final bool isSelected = option.title == _selectedGoal;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedGoal = option.title),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15191E),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4FD0F8)
                                : Colors.transparent,
                            width: 1.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              option.icon,
                              color: option.iconColor,
                              size: 23,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // 4. Bottom Cyan "Continue" Pill Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _onContinuePressed,
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
                          'Continue',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0A1014),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalOption {
  final String title;
  final IconData icon;
  final Color iconColor;

  const _GoalOption({
    required this.title,
    required this.icon,
    required this.iconColor,
  });
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_track/controller/auth_controller.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final cachedUser = authService.getCachedUser();
    final mainGoal = authService.getCachedMainGoal();
    final setupMetrics = authService.getCachedSetupMetrics();

    final String userName =
        (cachedUser?.name.trim().isNotEmpty ?? false)
            ? cachedUser!.name.trim()
            : 'StepTrack User';
    final String initial = userName[0].toUpperCase();
    final Color avatarColor = cachedUser?.avatarColorValue != null
        ? Color(cachedUser!.avatarColorValue!)
        : const Color(0xFF4FD0F8);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1016),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1016),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Color(0xFF0A1014),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Color(0xFF7D858E),
                    fontSize: 12,
                  ),
                ),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Replay Onboarding',
            onPressed: () {
              final controller = Get.isRegistered<AuthController>()
                  ? Get.find<AuthController>()
                  : Get.put(AuthController());
              controller.skipToOnboarding();(replaceStack: true);
            },
            icon: const Icon(
              Icons.replay_rounded,
              color: Color(0xFF4FD0F8),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF121820),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF1E2936),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'HOME SCREEN DEMO',
                      style: TextStyle(
                        color: Color(0xFF4FD0F8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Steps today (Demo)',
                      style: TextStyle(
                        color: Color(0xFF7D858E),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _InfoChip(
                          label: 'Goal: ${mainGoal ?? "Not set"}',
                        ),
                        if (setupMetrics?['weightKg'] != null)
                          _InfoChip(
                            label: 'Weight: ${setupMetrics!['weightKg']} kg',
                          ),
                        if (setupMetrics?['heightCm'] != null)
                          _InfoChip(
                            label: 'Height: ${setupMetrics!['heightCm']} cm',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final controller = Get.isRegistered<AuthController>()
                        ? Get.find<AuthController>()
                        : Get.put(AuthController());
                    controller.skipToOnboarding();(replaceStack: true);
                  },
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4FD0F8)),
                  label: const Text(
                    'Test Onboarding Flow Again',
                    style: TextStyle(
                      color: Color(0xFF4FD0F8),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF4FD0F8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
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

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1016),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2B38)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFCFD8E3),
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
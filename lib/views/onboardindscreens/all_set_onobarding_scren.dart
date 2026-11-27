import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class AllSetOnboardingScreen extends StatefulWidget {
  final int totalSteps;
  final VoidCallback? onLetsGo;

  const AllSetOnboardingScreen({
    super.key,
    this.totalSteps = 8,
    this.onLetsGo,
  });

  @override
  State<AllSetOnboardingScreen> createState() => _AllSetOnboardingScreenState();
}

class _AllSetOnboardingScreenState extends State<AllSetOnboardingScreen> {
  final AuthService _authService = AuthService();
  bool _isCompleting = false;

  Future<void> _markPerUserOnboardingDone() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    const boxName = 'steptrack_auth_box';
    final box =
        Hive.isBoxOpen(boxName) ? Hive.box(boxName) : await Hive.openBox(boxName);
    await box.put('onboarding_done_$uid', true);
  }

  Future<void> _onLetsGoPressed() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    try {
      final cachedUser = _authService.getCachedUser();
      await _authService.saveWelcomePreferences(
        subscribeNewsletter: cachedUser?.subscribeNewsletter ?? true,
        isOnboardingCompleted: true,
      );
      await _markPerUserOnboardingDone();

      if (!mounted) return;

      if (widget.onLetsGo != null) {
        widget.onLetsGo!();
      } else {
        Get.offAll(() => const HomeScreen());
      }
    } catch (e) {
      debugPrint('Complete onboarding error: $e');
      if (mounted) {
        Get.snackbar(
          'Error',
          'Onboarding complete karte waqt masla aaya. Dobara koshish karein.',
          backgroundColor: const Color(0xFF28181D),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int safeTotal = widget.totalSteps > 0 ? widget.totalSteps : 8;

    return Scaffold(
      backgroundColor: const Color(0xFF080A0C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
          child: Column(
            children: [
              // 1. Top Segmented Onboarding Progress Bars (8 steps consistent)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Row(
                  children: List.generate(safeTotal, (index) {
                    return Expanded(
                      child: Container(
                        height: 4.5,
                        margin: EdgeInsets.only(
                          right: index == safeTotal - 1 ? 0 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF19A7E6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const Spacer(flex: 3),

              // 2. Green Outlined Checkmark Badge
              Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF35D41B),
                    width: 8.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: Color(0xFF35D41B),
                    size: 74,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 3. Title: "You're All Set Up!"
              const Text(
                "You're All Set Up!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 14),

              // 4. Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  'Congrats, you can now start tracking\nyour steps!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7D858E),
                    fontSize: 17,
                    height: 1.38,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              const Spacer(flex: 4),

              // 5. Bottom Cyan "Let's Go!" Pill Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCompleting ? null : _onLetsGoPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FD0F8),
                    foregroundColor: const Color(0xFF0A1014),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isCompleting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF0A1014),
                          ),
                        )
                      : const Text(
                          "Let's Go!",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0A1014),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}
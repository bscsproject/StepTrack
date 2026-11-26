import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_track/main.dart';
import 'package:step_track/model/user_model.dart';
import 'package:step_track/services/auth_service.dart';
import 'package:step_track/views/auth/create_profile_screen.dart';
import 'package:step_track/views/auth/welcome_user_screen.dart';
import 'package:step_track/views/home/home_screen.dart';
import 'package:step_track/views/onboardindscreens/all_set_onobarding_scren.dart';
import 'package:step_track/views/onboardindscreens/autostart_onboarding_screen.dart';
import 'package:step_track/views/onboardindscreens/battery_optimization.dart';
import 'package:step_track/views/onboardindscreens/daily_circle_onboarding.dart';
import 'package:step_track/views/onboardindscreens/goal_onboarding_remainder.dart';
import 'package:step_track/views/onboardindscreens/goal_onboarding_screen.dart';
import 'package:step_track/views/onboardindscreens/motion_sensor.dart';
import 'package:step_track/views/onboardindscreens/setup_onboarding_screen.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Loading states
  var isLoading = false.obs;
  var isGoogleLoading = false.obs;

  // Profile creation state (Screen 1 & Screen 2)
  final List<Color> avatarColors = const [
    Color(0xFF2EC4B6), // Teal
    Color(0xFF00BBF9), // Cyan
    Color(0xFF4361EE), // Royal Blue
    Color(0xFF7209B7), // Deep Purple
    Color(0xFFB5179E), // Violet/Purple
    Color(0xFFFF4DA6), // Hot Pink
    Color(0xFFFF4D6D), // Coral Red
  ];

  var selectedColorIndex = 5.obs; // Default pink circle like screenshot
  var profileName = ''.obs;
  var profileDescription = ''.obs;
  var subscribeNewsletter = true.obs;

  void selectAvatarColor(int index) {
    selectedColorIndex.value = index;
  }

  void shuffleAvatarColor() {
    final next = (selectedColorIndex.value + 1) % avatarColors.length;
    selectedColorIndex.value = next;
  }

  // Skip -> Direct Onboarding
  void skipToOnboarding() {
    Get.offAll(() => const OnboardingScreen());
  }

  // 1. Signup with Email -> Create Profile Screen
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      final UserModel? user = await _authService.signUpWithEmail(
        name: name,
        email: email,
        password: password,
      );

      if (user != null) {
        profileName.value = user.name;
        Get.offAll(() => const CreateProfileScreen());
      }
    } catch (e) {
      Get.snackbar(
        'Signup Failed',
        e.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 2. Continue with Google -> Create Profile Screen (agar new/incomplete hai) ya Onboarding
  Future<void> continueWithGoogle() async {
    try {
      isGoogleLoading.value = true;
      final UserModel? user = await _authService.signInWithGoogle();

      if (user != null) {
        profileName.value = user.name;
        if (user.isOnboardingCompleted) {
          Get.offAll(() => const OnboardingScreen());
        } else {
          Get.offAll(() => const CreateProfileScreen());
        }
      }
    } catch (e) {
      Get.snackbar(
        'Google Sign-In Error',
        e.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isGoogleLoading.value = false;
    }
  }

  // 3. Login with Email -> Onboarding Screen
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      final user = await _authService.loginWithEmail(
        email: email,
        password: password,
      );

      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['name'] != null) {
          profileName.value = doc.data()!['name'];
        }
        Get.offAll(() => const OnboardingScreen());
      }
    } catch (e) {
      Get.snackbar(
        'Login Failed',
        e.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 4. Screen 1 ("Create Profile") Continue -> Save & Open Screen 2 ("Welcome!")
  Future<void> saveProfileAndGoWelcome({
    required String name,
    required String description,
  }) async {
    final cleanName = name.trim().isEmpty ? 'StepTrack User' : name.trim();
    profileName.value = cleanName;
    profileDescription.value = description.trim();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        isLoading.value = true;
        await _firestore.collection('users').doc(uid).set({
          'name': cleanName,
          'description': profileDescription.value,
          'avatarColorValue': avatarColors[selectedColorIndex.value].value,
        }, SetOptions(merge: true));
      } finally {
        isLoading.value = false;
      }
    }

    Get.to(() => const WelcomeUserScreen());
  }

  // 5. Screen 2 ("Welcome!") Continue -> Save Newsletter & Go to OnboardingScreen
  Future<void> completeWelcomeToOnboarding() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        isLoading.value = true;
        await _firestore.collection('users').doc(uid).set({
          'subscribeNewsletter': subscribeNewsletter.value,
          'isOnboardingCompleted': true,
        }, SetOptions(merge: true));
      } finally {
        isLoading.value = false;
      }
    }

    Get.offAll(() => const OnboardingScreen());
  }
}

/// Complete Onboarding Flow Navigation for StepTrack
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _openStep(Widget page) {
    Get.to(() => page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080A0C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'StepTrack Onboarding Flow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Har step par tap karke ya sequence mein flow test karein:',
                style: TextStyle(color: Color(0xFF7D858E), fontSize: 14),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _OnboardingStepTile(
                      step: '1',
                      title: 'Motion Sensor',
                      onTap: () => _openStep(
                        MotionSensorOnboardingScreen(
                          onContinue: () => _openStep(
                            SetupOnboardingScreen(
                              onContinue: () => _openStep(
                                GoalOnboardingScreen(
                                  onContinue: () => _openStep(
                                    GoalReminderOnboardingScreen(
                                      onContinue: () => _openStep(
                                        DailyCircleOnboardingScreen(
                                          onGetStarted: () => _openStep(
                                            BatteryOptimisationOnboardingScreen(
                                              onContinue: () => _openStep(
                                                EnableAutostartOnboardingScreen(
                                                  onContinue: () => _openStep(
                                                    AllSetOnboardingScreen(
                                                      onLetsGo: () => Get.offAll(
                                                        () => const HomeScreen(),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _OnboardingStepTile(
                      step: '2',
                      title: 'Setup Metrics',
                      onTap: () => _openStep(
  SetupOnboardingScreen(onContinue: () {}),
),
                    ),
                    _OnboardingStepTile(
                      step: '3',
                      title: 'Main Goal',
                      onTap: () => _openStep(const GoalOnboardingScreen()),
                    ),
                    _OnboardingStepTile(
                      step: '4',
                      title: 'Goal Reminder',
                      onTap: () =>
                          _openStep(const GoalReminderOnboardingScreen()),
                    ),
                    _OnboardingStepTile(
                      step: '5',
                      title: 'Daily Circle',
                      onTap: () =>
                          _openStep(const DailyCircleOnboardingScreen()),
                    ),
                    _OnboardingStepTile(
                      step: '6',
                      title: 'Battery Optimisation',
                      onTap: () => _openStep(
                        const BatteryOptimisationOnboardingScreen(),
                      ),
                    ),
                    _OnboardingStepTile(
                      step: '7',
                      title: 'Enable Autostart',
                      onTap: () => _openStep(
                        const EnableAutostartOnboardingScreen(),
                      ),
                    ),
                    _OnboardingStepTile(
                      step: '8',
                      title: "You're All Set Up!",
                      onTap: () => _openStep(
                        AllSetOnboardingScreen(
                          onLetsGo: () => Get.offAll(() => const HomeScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Get.offAll(() => const HomeScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FD0F8),
                    foregroundColor: const Color(0xFF0A1014),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Go to HomeScreen',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

class _OnboardingStepTile extends StatelessWidget {
  final String step;
  final String title;
  final VoidCallback onTap;

  const _OnboardingStepTile({
    required this.step,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF12161B),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF19A7E6),
          foregroundColor: const Color(0xFF0A1014),
          child: Text(step, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF4FD0F8)),
        onTap: onTap,
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  var selectedColorIndex = 5.obs;
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

  // =========================================================================
  // DIRECT STEP-BY-STEP ONBOARDING FLOW (Step 1 -> Step 8 -> HomeScreen)
  // =========================================================================

  /// Auth complete hone ke baad seedha Step 1 (Motion Sensor) se flow start karta hai
  void startOnboardingFlow() {
    Get.offAll(() => _buildStep1MotionSensor());
  }

  Widget _buildStep1MotionSensor() {
    return MotionSensorOnboardingScreen(
      onContinue: () => Get.to(() => _buildStep2SetupMetrics()),
    );
  }

  Widget _buildStep2SetupMetrics() {
    return SetupOnboardingScreen(
      onContinue: () => Get.to(() => _buildStep3MainGoal()),
    );
  }

  Widget _buildStep3MainGoal() {
    return GoalOnboardingScreen(
      onContinue: () => Get.to(() => _buildStep4GoalReminder()),
    );
  }

  Widget _buildStep4GoalReminder() {
    return GoalReminderOnboardingScreen(
      onContinue: () => Get.to(() => _buildStep5DailyCircle()),
    );
  }

  Widget _buildStep5DailyCircle() {
    return DailyCircleOnboardingScreen(
      onGetStarted: () => Get.to(() => _buildStep6BatteryOptimisation()),
    );
  }

  Widget _buildStep6BatteryOptimisation() {
    return BatteryOptimisationOnboardingScreen(
      onContinue: () => Get.to(() => _buildStep7EnableAutostart()),
    );
  }

  Widget _buildStep7EnableAutostart() {
    return EnableAutostartOnboardingScreen(
      onContinue: () => Get.to(() => _buildStep8AllSetUp()),
    );
  }

  Widget _buildStep8AllSetUp() {
    return AllSetOnboardingScreen(
      onLetsGo: finishOnboardingAndGoHome,
    );
  }

  /// Final step ("Go to HomeScreen" / "Let's Go") par completion save karke HomeScreen open karta hai
  Future<void> finishOnboardingAndGoHome() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        isLoading.value = true;
        await _firestore.collection('users').doc(uid).set({
          'isOnboardingCompleted': true,
        }, SetOptions(merge: true));
      } finally {
        isLoading.value = false;
      }
    }
    Get.offAll(() => const HomeScreen());
  }

  // =========================================================================
  // AUTH ACTIONS
  // =========================================================================

  // Skip -> Direct Step 1 (Motion Sensor)
  void skipToOnboarding() {
    startOnboardingFlow();
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

  // 2. Continue with Google -> Direct Home (agar onboarding completed hai) ya Create Profile
  Future<void> continueWithGoogle() async {
    try {
      isGoogleLoading.value = true;
      final UserModel? user = await _authService.signInWithGoogle();

      if (user != null) {
        profileName.value = user.name;
        if (user.isOnboardingCompleted) {
          Get.offAll(() => const HomeScreen());
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

  // 3. Login with Email -> Agar onboarding complete hai to Home, warna Step 1 (Motion Sensor)
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
        final data = doc.data();
        if (data != null && data['name'] != null) {
          profileName.value = data['name'];
        }

        final bool completed = data?['isOnboardingCompleted'] == true;
        if (completed) {
          Get.offAll(() => const HomeScreen());
        } else {
          startOnboardingFlow();
        }
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

  // 5. Screen 2 ("Welcome!") Continue -> Save Newsletter & Direct Start Step 1 (Motion Sensor)
  Future<void> completeWelcomeToOnboarding() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        isLoading.value = true;
        await _firestore.collection('users').doc(uid).set({
          'subscribeNewsletter': subscribeNewsletter.value,
        }, SetOptions(merge: true));
      } finally {
        isLoading.value = false;
      }
    }

    startOnboardingFlow();
  }
}
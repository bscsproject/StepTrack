
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:step_track/model/user_model.dart';
import 'package:step_track/services/auth_service.dart';
import 'package:step_track/views/auth/create_profile_screen.dart';
import 'package:step_track/views/auth/welcome_user_screen.dart';

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

  // ============================================================
  // LOADING STATES
  // ============================================================

  final RxBool isLoading = false.obs;
  final RxBool isGoogleLoading = false.obs;

  // ============================================================
  // PROFILE CREATION STATE
  // ============================================================

  final List<Color> avatarColors = const [
    Color(0xFF2EC4B6),
    Color(0xFF00BBF9),
    Color(0xFF4361EE),
    Color(0xFF7209B7),
    Color(0xFFB5179E),
    Color(0xFFFF4DA6),
    Color(0xFFFF4D6D),
  ];

  final RxInt selectedColorIndex = 5.obs;
  final RxString profileName = ''.obs;
  final RxString profileDescription = ''.obs;
  final RxBool subscribeNewsletter = true.obs;

  void selectAvatarColor(int index) {
    if (index >= 0 && index < avatarColors.length) {
      selectedColorIndex.value = index;
    }
  }

  void shuffleAvatarColor() {
    selectedColorIndex.value =
        (selectedColorIndex.value + 1) % avatarColors.length;
  }

  // ============================================================
  // LOCAL ONBOARDING STORAGE
  // ============================================================

  Future<void> _setLocalOnboardingCompleted(bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      debugPrint('AUTH: Cannot save onboarding status; UID is missing.');
      return;
    }

    const boxName = 'steptrack_auth_box';
    final box = Hive.isBoxOpen(boxName)
        ? Hive.box(boxName)
        : await Hive.openBox(boxName);

    await box.put('onboarding_done_$uid', value);
    // Once a real account is active, discard any previous guest completion.
    await box.delete('guest_onboarding_done');
    debugPrint('AUTH: Local onboarding status saved: $value');
  }

  // ============================================================
  // COMMON ONBOARDING NAVIGATION
  // ============================================================

  void _replaceOnboardingStep(
    Widget Function() pageBuilder,
    String stepName,
  ) {
    debugPrint('ONBOARDING: Navigating to $stepName');

    Get.off(
      () => pageBuilder(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// Auth / Welcome ke baad onboarding ka first screen open karein.
  ///
  /// Flow:
  /// Motion Sensor -> Setup Metrics -> Main Goal -> Goal Reminder
  /// -> Daily Circle -> Battery -> Autostart -> All Set -> Home
  void startOnboardingFlow() {
    debugPrint('AUTH: Starting onboarding flow from Step 1');

    Get.offAll(
      () => _buildStep1MotionSensor(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  // ============================================================
  // STEP 1: MOTION SENSOR
  // ============================================================

  Widget _buildStep1MotionSensor() {
    return MotionSensorOnboardingScreen(
      totalSteps: 8,
      currentStep: 0,
      onContinue: _navigateToStep2,
    );
  }

  void _navigateToStep2() {
    debugPrint('AUTH: Step 1 Continue callback received');

    _replaceOnboardingStep(
      _buildStep2SetupMetrics,
      'Step 2 - Setup Metrics',
    );
  }

  // ============================================================
  // STEP 2: SETUP METRICS
  // ============================================================

  Widget _buildStep2SetupMetrics() {
    return SetupOnboardingScreen(
      totalSteps: 8,
      currentStep: 1,
      onContinue: _navigateToStep3,
    );
  }

  void _navigateToStep3() {
    debugPrint('AUTH: Step 2 Next callback received');

    _replaceOnboardingStep(
      _buildStep3MainGoal,
      'Step 3 - Main Goal',
    );
  }

  // ============================================================
  // STEP 3: MAIN GOAL
  // ============================================================

  Widget _buildStep3MainGoal() {
    return GoalOnboardingScreen(
      onContinue: _navigateToStep4,
    );
  }

  void _navigateToStep4() {
    debugPrint('AUTH: Step 3 Continue callback received');

    _replaceOnboardingStep(
      _buildStep4GoalReminder,
      'Step 4 - Goal Reminder',
    );
  }

  // ============================================================
  // STEP 4: GOAL REMINDER
  // ============================================================

  Widget _buildStep4GoalReminder() {
    return GoalReminderOnboardingScreen(
      onContinue: _navigateToStep5,
    );
  }

  void _navigateToStep5() {
    debugPrint('AUTH: Step 4 Continue callback received');

    _replaceOnboardingStep(
      _buildStep5DailyCircle,
      'Step 5 - Daily Circle',
    );
  }

  // ============================================================
  // STEP 5: DAILY CIRCLE
  // ============================================================

  Widget _buildStep5DailyCircle() {
    return DailyCircleOnboardingScreen(
      onGetStarted: _navigateToStep6,
    );
  }

  void _navigateToStep6() {
    debugPrint('AUTH: Step 5 Get Started callback received');

    _replaceOnboardingStep(
      _buildStep6BatteryOptimisation,
      'Step 6 - Battery Optimisation',
    );
  }

  // ============================================================
  // STEP 6: BATTERY OPTIMISATION
  // ============================================================

  Widget _buildStep6BatteryOptimisation() {
    return BatteryOptimisationOnboardingScreen(
      onContinue: _navigateToStep7,
    );
  }

  void _navigateToStep7() {
    debugPrint('AUTH: Step 6 Continue callback received');

    _replaceOnboardingStep(
      _buildStep7EnableAutostart,
      'Step 7 - Enable Autostart',
    );
  }

  // ============================================================
  // STEP 7: ENABLE AUTOSTART
  // ============================================================

  Widget _buildStep7EnableAutostart() {
    return EnableAutostartOnboardingScreen(
      onContinue: _navigateToStep8,
    );
  }

  void _navigateToStep8() {
    debugPrint('AUTH: Step 7 Continue callback received');

    _replaceOnboardingStep(
      _buildStep8AllSetUp,
      'Step 8 - All Set',
    );
  }

  // ============================================================
  // STEP 8: ALL SET
  // ============================================================

  Widget _buildStep8AllSetUp() {
    return AllSetOnboardingScreen(
      onLetsGo: finishOnboardingAndGoHome,
    );
  }

  // ============================================================
  // FINISH ONBOARDING -> HOME
  // ============================================================

  Future<void> finishOnboardingAndGoHome() async {
    // Prevent rapid repeated taps / duplicate route pushes.
    if (isLoading.value) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      isLoading.value = true;

      if (uid == null) {
        // Welcome Auth has a Skip option, so support guest onboarding too.
        const boxName = 'steptrack_auth_box';
        final box = Hive.isBoxOpen(boxName)
            ? Hive.box(boxName)
            : await Hive.openBox(boxName);
        await box.put('guest_onboarding_done', true);

        debugPrint('AUTH: Guest onboarding completion saved locally.');
        Get.offAllNamed('/home');
        return;
      }

      // Save remotely first. Do not mark local completion if this fails.
      await _firestore.collection('users').doc(uid).set(
        {'isOnboardingCompleted': true},
        SetOptions(merge: true),
      );

      // Keep SplashScreen and AuthController on the same per-user key.
      await _setLocalOnboardingCompleted(true);

      debugPrint('AUTH: Onboarding completion saved successfully.');

      // Navigate only after both persistence operations succeed.
      Get.offAllNamed('/home');
    } catch (e, stackTrace) {
      debugPrint('AUTH: Final onboarding save failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      Get.snackbar(
        'Could Not Finish Setup',
        'Your progress was not confirmed as saved. Please try again.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      // AllSetOnboardingScreen catches this and keeps its retry button usable.
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // AUTH ACTIONS
  // ============================================================

  // Skip / Start onboarding
  void skipToOnboarding() {
    startOnboardingFlow();
  }

  // ------------------------------------------------------------
  // 1. EMAIL SIGNUP -> CREATE PROFILE
  // ------------------------------------------------------------

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

        await _setLocalOnboardingCompleted(false);

        Get.offAll(() => const CreateProfileScreen());
      }
    } catch (e) {
      debugPrint('AUTH: Signup error: $e');

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

  // ------------------------------------------------------------
  // 2. GOOGLE SIGN-IN
  // ------------------------------------------------------------

  Future<void> continueWithGoogle() async {
    try {
      isGoogleLoading.value = true;

      final UserModel? user = await _authService.signInWithGoogle();

      if (user != null) {
        profileName.value = user.name;

        await _setLocalOnboardingCompleted(
          user.isOnboardingCompleted,
        );

        if (user.isOnboardingCompleted) {
          debugPrint('AUTH: Google user already completed onboarding.');

          Get.offAllNamed('/home');
        } else {
          startOnboardingFlow();
        }
      }
    } catch (e) {
      debugPrint('AUTH: Google sign-in error: $e');

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

  // ------------------------------------------------------------
  // 3. EMAIL LOGIN
  // ------------------------------------------------------------

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
        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        final data = doc.data();

        if (data != null && data['name'] != null) {
          profileName.value = data['name'];
        }

        final bool completed =
            data?['isOnboardingCompleted'] == true;

        await _setLocalOnboardingCompleted(completed);

        if (completed) {
          debugPrint('AUTH: User onboarding already completed.');

          Get.offAllNamed('/home');
        } else {
          startOnboardingFlow();
        }
      }
    } catch (e) {
      debugPrint('AUTH: Login error: $e');

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

  // ------------------------------------------------------------
  // 4. CREATE PROFILE -> WELCOME SCREEN
  // ------------------------------------------------------------

  Future<void> saveProfileAndGoWelcome({
    required String name,
    required String description,
  }) async {
    final cleanName =
        name.trim().isEmpty ? 'StepTrack User' : name.trim();

    profileName.value = cleanName;
    profileDescription.value = description.trim();

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      try {
        isLoading.value = true;

        await _firestore.collection('users').doc(uid).set(
          {
            'name': cleanName,
            'description': profileDescription.value,
            'avatarColorValue':
                avatarColors[selectedColorIndex.value].value,
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('AUTH: Save profile error: $e');
        rethrow;
      } finally {
        isLoading.value = false;
      }
    }

    Get.off(() => const WelcomeUserScreen());
  }

  // ------------------------------------------------------------
  // 5. WELCOME SCREEN -> ONBOARDING
  // ------------------------------------------------------------

  Future<void> completeWelcomeToOnboarding() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      try {
        isLoading.value = true;

        await _firestore.collection('users').doc(uid).set(
          {
            'subscribeNewsletter': subscribeNewsletter.value,
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('AUTH: Save newsletter error: $e');
        rethrow;
      } finally {
        isLoading.value = false;
      }
    }

    startOnboardingFlow();
  }
}

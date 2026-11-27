import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:step_track/controller/auth_controller.dart';
import 'package:step_track/controller/social_realtime_controller.dart';
import 'package:step_track/controller/suite_realtime_controller.dart';
import 'package:step_track/core/app_theme.dart';
import 'package:step_track/firebase_options.dart';
import 'package:step_track/model/groups_modal_screen.dart';
import 'package:step_track/views/auth/create_profile_screen.dart';
import 'package:step_track/views/auth/login_screen.dart';
import 'package:step_track/views/auth/signup_screen.dart';
import 'package:step_track/views/auth/welcome_auth_screen.dart';
import 'package:step_track/views/auth/welcome_user_screen.dart';
import 'package:step_track/views/chat/chat_screen.dart';
import 'package:step_track/views/chat/chats_home_screen.dart';
import 'package:step_track/views/chat/stepsapp_feed_screen.dart';
import 'package:step_track/views/chat/thread_conversation_screen.dart';
import 'package:step_track/views/discover/discover_screen.dart';
import 'package:step_track/views/discover/previous_challenges_screen.dart';
import 'package:step_track/views/discover/social_hub_screen.dart';
import 'package:step_track/views/home/create_challenge_screen.dart';
import 'package:step_track/views/home/home_screen.dart';
import 'package:step_track/views/home/weight_loss_plan_screen.dart';
import 'package:step_track/views/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Initialize Firebase
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // 2. Initialize Hive
    await Hive.initFlutter();

    // 3. Open authentication & onboarding box
    if (!Hive.isBoxOpen('steptrack_auth_box')) {
      await Hive.openBox('steptrack_auth_box');
    }

    // 4. Register GetX controllers
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(),
        permanent: true,
      );
    }
    if (!Get.isRegistered<SocialRealtimeController>()) {
      Get.put<SocialRealtimeController>(
        SocialRealtimeController(),
        permanent: true,
      );
    }
    if (!Get.isRegistered<SuiteRealtimeController>()) {
      Get.put<SuiteRealtimeController>(
        SuiteRealtimeController(),
        permanent: true,
      );
    }

    // 5. Run application
    runApp(const StepTrackApp());
  } catch (error, stackTrace) {
    debugPrint('STEPTRACK STARTUP ERROR: $error');
    debugPrintStack(stackTrace: stackTrace);

    runApp(
      StartupErrorApp(error: error.toString()),
    );
  }
}

class StepTrackApp extends StatelessWidget {
  const StepTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StepTrack',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: '/splash',
      getPages: [
        // Core App Flow: Splash -> Auth -> Onboarding (via AuthController) -> Home
        GetPage(
          name: '/splash',
          page: () => SplashScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/auth',
          page: () =>  WelcomeAuthScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/login',
          page: () => const LoginScreen(),
          transition: Transition.rightToLeftWithFade,
        ),
        GetPage(
          name: '/signup',
          page: () => const SignupScreen(),
          transition: Transition.rightToLeftWithFade,
        ),
        GetPage(
          name: '/create-profile',
          page: () => const CreateProfileScreen(),
          transition: Transition.rightToLeftWithFade,
        ),
        GetPage(
          name: '/welcome-user',
          page: () => const WelcomeUserScreen(),
          transition: Transition.rightToLeftWithFade,
        ),
        GetPage(
          name: '/home',
          page: () => const HomeScreen(),
          transition: Transition.fadeIn,
        ),

        // Bottom Navigation & Sub-Screens (Home, Discover, Chat, Insight)
        GetPage(
          name: '/social-hub',
          page: () => const SocialHubScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/chat',
          page: () => const ChatScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/discover',
          page: () => const DiscoverScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/create-challenge',
          page: () => const CreateChallengeScreen(),
        ),
        GetPage(
          name: '/groups-modal',
          page: () => const GroupsModalScreen(),
        ),
        GetPage(
          name: '/previous-challenges',
          page: () => const PreviousChallengesScreen(),
        ),
        GetPage(
          name: '/weight-loss-plan',
          page: () => const WeightLossPlanScreen(),
        ),
        GetPage(
          name: '/chats-home',
          page: () => const ChatsHomeScreen(),
        ),
        GetPage(
          name: '/stepsapp-feed',
          page: () => const StepsAppFeedScreen(),
        ),
        GetPage(
          name: '/thread-conversation',
          page: () => const ThreadConversationScreen(),
        ),
      ],
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  final String error;

  const StartupErrorApp({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        backgroundColor: const Color(0xFF0D1020),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'StepTrack could not start.\n\n$error',
              style: const TextStyle(
                color: Color(0xFFF7F7FF),
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
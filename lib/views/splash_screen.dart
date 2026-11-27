import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:step_track/controller/auth_controller.dart';
import 'package:step_track/core/app_theme.dart';
import 'package:step_track/views/auth/welcome_auth_screen.dart';
import 'package:step_track/views/home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _isRouting = false;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      unawaited(_routeUser());
    });
  }

  Future<void> _routeUser() async {
    if (_isRouting) return;
    _isRouting = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        Get.offAll(() =>  WelcomeAuthScreen());
        return;
      }

      bool isOnboardingDone = false;
      const boxName = 'steptrack_auth_box';

      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        isOnboardingDone = box.get('onboarding_done_${user.uid}') == true;
      } else {
        try {
          final box = await Hive.openBox(boxName);
          isOnboardingDone = box.get('onboarding_done_${user.uid}') == true;
        } catch (e) {
          debugPrint('Splash Hive read error: $e');
        }
      }

      if (!mounted) return;

      if (isOnboardingDone) {
        Get.offAll(() => const HomeScreen());
      } else if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().startOnboardingFlow();
      } else {
        Get.offAll(() =>  WelcomeAuthScreen());
      }
    } catch (e) {
      debugPrint('Splash routing error: $e');
      if (!mounted) return;
      Get.offAll(() =>  WelcomeAuthScreen());
    } finally {
      _isRouting = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1020),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF171B38),
              Color(0xFF0D1020),
              Color(0xFF10172B),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8265FF).withValues(alpha: 0.20),
                        blurRadius: 35,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'app_mockup/steptrack_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.directions_walk_rounded,
                          size: 90,
                          color: Color(0xFF8265FF),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // App Name
                ShaderMask(
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      colors: [
                        Color(0xFF8265FF),
                        Color(0xFF35B9FF),
                      ],
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'StepTrack',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Every step brings you closer.',
                  style: TextStyle(
                    color: Color(0xFFA5AAC1),
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 55),

                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF8265FF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
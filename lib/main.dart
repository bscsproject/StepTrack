
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:step_track/core/app_theme.dart';

import 'package:step_track/views/splash_screen.dart';

import 'firebase_options.dart';

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

    // 3. Open authentication box
    if (!Hive.isBoxOpen('steptrack_auth_box')) {
      await Hive.openBox('steptrack_auth_box');
    }

    // 4. Run application
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

      home: SplashScreen(),
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

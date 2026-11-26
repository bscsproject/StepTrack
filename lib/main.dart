import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:step_track/core/app_theme.dart';
import 'package:step_track/views/auth/welcome_auth_screen.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  await Hive.openBox('steptrack_auth_box');
  runApp(const StepTrackApp());
}

class StepTrackApp extends StatelessWidget {
  const StepTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StepTrack',
      theme: AppTheme.darkTheme,
      // Pehle SplashScreen rakhni ho to SplashScreen() bhi laga sakte hain;
      // abhi direct WelcomeAuthScreen set ki hai jahan se Skip / Sign In / Sign up chalega:
      home: WelcomeAuthScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'app_mockup/steptrack_logo.png',
                width: 130,
                height: 130,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              Text(
                'StepTrack',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Track Your Steps. Reach Your Goals.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
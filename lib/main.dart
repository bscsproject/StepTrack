
import 'package:flutter/material.dart';
import 'package:step_track/core/app_theme.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StepTrackApp());
}

class StepTrackApp extends StatelessWidget {
  const StepTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'StepTrack',
  theme: AppTheme.darkTheme,
  home: const HomeScreen(),
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

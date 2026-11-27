import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_track/controller/step_track_hub_controller.dart';
import 'package:step_track/themes/step_track_theme.dart';

class SetupStepCounterFlow extends StatefulWidget {
  const SetupStepCounterFlow({super.key});

  @override
  State<SetupStepCounterFlow> createState() => _SetupStepCounterFlowState();
}

class _SetupStepCounterFlowState extends State<SetupStepCounterFlow> {
  int _stage = 0;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<StepTrackHubController>();
    final p = ctrl.prefs.value;
    final pal = StepTrackPalette.resolve(
      context,
      themeMode: p.themeMode,
      accent: Color(p.accentColorValue),
    );

    return Scaffold(
      backgroundColor: pal.screenBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Spacer(),
              if (_stage == 0) ...[
                const Icon(
                  Icons.battery_charging_full,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 20),
                Text(
                  'Setup Step Counter',
                  style: TextStyle(
                    color: pal.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Let's quickly set everything up so that StepTrack can reliably count your steps.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: pal.textSecondary, fontSize: 16),
                ),
              ] else if (_stage == 1) ...[
                const Icon(Icons.battery_std, color: Colors.green, size: 78),
                const SizedBox(height: 20),
                Text(
                  'Battery optimisation',
                  style: TextStyle(
                    color: pal.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "This makes sure that StepTrack can count your steps when you don't have the app open.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: pal.textSecondary, fontSize: 16),
                ),
              ] else ...[
                const CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 20),
                Text(
                  'Setup Complete',
                  style: TextStyle(
                    color: pal.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your step counter is now set up.',
                  style: TextStyle(color: pal.textSecondary, fontSize: 16),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_stage == 0) {
                      setState(() => _stage = 1);
                    } else if (_stage == 1) {
                      await ctrl.requestBatteryOptimisation();
                      if (mounted) setState(() => _stage = 2);
                    } else {
                      Get.back();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pal.accent,
                    foregroundColor: pal.onAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    _stage < 2 ? 'Continue' : 'Done',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
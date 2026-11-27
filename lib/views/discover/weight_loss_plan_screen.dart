import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:step_track/controller/suite_realtime_controller.dart';

class WeightLossPlanScreen extends StatelessWidget {
  static const String routeName = '/discover/weight-loss-plan';

  const WeightLossPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SuiteRealtimeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Weight Loss & Cardio Plan')),
      body: Obx(() {
        final plans = c.fitnessPlans;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Maintain brisk walking blocks across the day and log steps to track real-time progress in Firestore.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (plans.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No fitness plan challenges found.'),
                ),
              )
            else
              ...plans.map((dynamic p) {
                final String title = (p?.title ?? '').toString();
                final String description = (p?.description ?? '').toString();
                final double progress =
                    ((p?.progress ?? 0.0) as num).toDouble().clamp(0.0, 1.0);
                final int currentSteps = ((p?.currentSteps ?? 0) as num).toInt();
                final int targetSteps = ((p?.targetSteps ?? 0) as num).toInt();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(description),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 6),
                        Text(
                          '${NumberFormat.decimalPattern().format(currentSteps)} / ${NumberFormat.decimalPattern().format(targetSteps)} steps',
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonal(
                          onPressed: () => c.incrementChallengeSteps(p, 1000),
                          child: const Text('+1,000 Plan Steps'),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      }),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/suite_realtime_controller.dart';

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
              ...plans.map(
                (p) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(p.description),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: p.progress),
                        const SizedBox(height: 6),
                        Text(
                          '${NumberFormat.decimalPattern().format(p.currentSteps)} / ${NumberFormat.decimalPattern().format(p.targetSteps)} steps',
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonal(
                          onPressed: () => c.incrementChallengeSteps(p, 1000),
                          child: const Text('+1,000 Plan Steps'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

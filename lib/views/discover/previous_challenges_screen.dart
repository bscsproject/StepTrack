import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:step_track/controller/suite_realtime_controller.dart';

class PreviousChallengesScreen extends StatelessWidget {
  static const String routeName = '/discover/previous-challenges';

  const PreviousChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SuiteRealtimeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Previous Challenges')),
      body: Obx(() {
        final list = c.previousChallenges;
        if (list.isEmpty) {
          return const Center(
            child: Text('No completed or past challenges recorded yet.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.emoji_events),
                title: Text(item.title),
                subtitle: Text(item.description),
                trailing: Text(
                  '${NumberFormat.decimalPattern().format(item.currentSteps)} steps',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

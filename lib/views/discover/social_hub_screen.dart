import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:step_track/controller/social_realtime_controller.dart';
import 'package:step_track/views/chat/chat_screen.dart';

import 'discover_screen.dart';

class SocialHubScreen extends StatelessWidget {
  static const String routeName = '/social-hub';

  const SocialHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SocialRealtimeController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('StepTrack Social Hub'),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Seed Sample Firestore Data',
              icon: controller.isSeeding.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              onPressed: controller.isSeeding.value
                  ? null
                  : controller.seedSampleRealtimeData,
            ),
          ),
        ],
      ),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      controller.isStreamConnected.value
                          ? Icons.sensors
                          : Icons.sensors_off,
                      color: controller.isStreamConnected.value
                          ? Colors.teal
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.isStreamConnected.value
                                ? 'Real-Time Firestore Streams Active'
                                : 'Connecting to Firestore...',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Live updates for Chat threads, messages, challenges, and members.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _HubSummaryCard(
                    title: 'Active Chats',
                    value: '${controller.threads.length}',
                    subtitle: '${controller.totalUnreadCount} unread',
                    icon: Icons.forum_outlined,
                    onTap: () => Get.toNamed(ChatScreen.routeName),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HubSummaryCard(
                    title: 'Challenges',
                    value: '${controller.challenges.length}',
                    subtitle: '${controller.joinedChallengesCount} joined',
                    icon: Icons.emoji_events_outlined,
                    onTap: () => Get.toNamed(DiscoverScreen.routeName),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.directions_walk),
                title: const Text('Live Challenge Steps Pool'),
                subtitle: const Text('Aggregated real-time progress across challenges'),
                trailing: Text(
                  NumberFormat.decimalPattern()
                      .format(controller.totalChallengeSteps),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Get.toNamed(ChatScreen.routeName),
              icon: const Icon(Icons.chat),
              label: const Text('Open Dedicated Chat Screen'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () => Get.toNamed(DiscoverScreen.routeName),
              icon: const Icon(Icons.explore),
              label: const Text('Open Dedicated Discover Screen'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HubSummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:step_track/controller/suite_realtime_controller.dart';
import 'package:step_track/views/discover/suite_navigation_bar.dart';
import 'thread_conversation_screen.dart';

class ChatsHomeScreen extends StatelessWidget {
  static const String routeName = '/chats-suite';

  const ChatsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SuiteRealtimeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            tooltip: 'New Chat Room',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () => _showCreateRoomDialog(c),
          ),
        ],
      ),
      bottomNavigationBar: const SuiteNavigationBar(currentIndex: 1),
      body: Obx(() {
        if (c.threads.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No chat rooms yet.'),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: c.seedSuiteSampleData,
                  child: const Text('Load Sample Rooms'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: c.threads.length,
          itemBuilder: (context, index) {
            final t = c.threads[index];
            final timeStr =
                t.updatedAt != null ? DateFormat.jm().format(t.updatedAt!) : '';

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(t.title.isNotEmpty ? t.title[0].toUpperCase() : 'C'),
                ),
                title: Text(t.title),
                subtitle: Text('${t.lastSender}: ${t.lastMessage}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (timeStr.isNotEmpty)
                      Text(timeStr, style: Theme.of(context).textTheme.bodySmall),
                    if (t.unreadCount > 0)
                      Badge(label: Text('${t.unreadCount}')),
                  ],
                ),
                onTap: () {
                  c.openThread(t.id, t.title);
                  Get.toNamed(ThreadConversationScreen.routeName);
                },
              ),
            );
          },
        );
      }),
    );
  }

  void _showCreateRoomDialog(SuiteRealtimeController c) {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController(text: "Ready for today's walk!");

    Get.dialog(
      AlertDialog(
        title: const Text('New Chat Thread'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Thread Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: msgCtrl,
              decoration: const InputDecoration(
                labelText: 'Opening Message',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await c.createNewThread(titleCtrl.text, msgCtrl.text);
              Get.back();
              Get.toNamed(ThreadConversationScreen.routeName);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
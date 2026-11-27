import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/social_realtime_controller.dart';
import '../models/social_models.dart';
import '../widgets/social_nav_bar.dart';
import 'discover_screen.dart';
import 'social_hub_screen.dart';

class ChatScreen extends StatefulWidget {
  static const String routeName = '/chat';

  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SocialRealtimeController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chat Screen'),
              Text(
                controller.activeThreadTitle.value.isEmpty
                    ? 'Real-Time Step Messaging'
                    : controller.activeThreadTitle.value,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'New Group Chat',
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () => _showNewThreadDialog(controller),
          ),
          IconButton(
            tooltip: 'Go to Discover Screen',
            icon: const Icon(Icons.explore_outlined),
            onPressed: () => Get.offNamed(DiscoverScreen.routeName),
          ),
          IconButton(
            tooltip: 'Back to Hub',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => Get.offAllNamed(SocialHubScreen.routeName),
          ),
        ],
      ),
      bottomNavigationBar: const SocialNavBar(currentIndex: 1),
      body: Obx(() {
        final threads = controller.threads;
        final messages = controller.activeMessages;

        return Column(
          children: [
            if (threads.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.chat_outlined),
                    title: const Text('No chat threads in Firestore yet'),
                    subtitle: const Text(
                      'Create a new chat room or load sample data.',
                    ),
                    trailing: FilledButton(
                      onPressed: controller.seedSampleRealtimeData,
                      child: const Text('Seed Data'),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 62,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: threads.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final ChatThreadModel thread = threads[index];
                    final isSelected = thread.id == controller.activeThreadId.value;
                    return ChoiceChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(thread.title),
                          if (thread.unreadCount > 0) ...[
                            const SizedBox(width: 6),
                            CircleAvatar(
                              radius: 9,
                              child: Text(
                                '${thread.unreadCount}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                      onSelected: (_) =>
                          controller.selectThread(thread.id, thread.title),
                    );
                  },
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.forum_outlined, size: 42),
                            const SizedBox(height: 10),
                            const Text('No messages in this room yet.'),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => Get.toNamed(
                                DiscoverScreen.routeName,
                              ),
                              icon: const Icon(Icons.explore),
                              label: const Text('Explore Challenges in Discover'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == controller.currentUserId;
                        final timeLabel = msg.createdAt != null
                            ? DateFormat.jm().format(msg.createdAt!)
                            : 'Live';

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.76,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.senderName,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(msg.text),
                                const SizedBox(height: 3),
                                Text(
                                  timeLabel,
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (val) {
                          controller.sendMessage(val);
                          _messageController.clear();
                        },
                        decoration: const InputDecoration(
                          hintText: 'Write a real-time step update...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        controller.sendMessage(_messageController.text);
                        _messageController.clear();
                      },
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showNewThreadDialog(SocialRealtimeController controller) {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController(
      text: 'Hello everyone! Ready for today's steps.',
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Create Chat Thread'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Room / Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: msgCtrl,
              decoration: const InputDecoration(
                labelText: 'First Message',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await controller.createThread(
                title: titleCtrl.text,
                initialMessage: msgCtrl.text,
              );
              Get.back();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

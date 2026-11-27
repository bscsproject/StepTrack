import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:step_track/controller/suite_realtime_controller.dart';

class ThreadConversationScreen extends StatefulWidget {
  static const String routeName = '/chats/thread';

  const ThreadConversationScreen({super.key});

  @override
  State<ThreadConversationScreen> createState() =>
      _ThreadConversationScreenState();
}

class _ThreadConversationScreenState extends State<ThreadConversationScreen> {
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SuiteRealtimeController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(c.activeThreadTitle.value)),
      ),
      body: Obx(
        () => Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: c.messages.length,
                itemBuilder: (context, index) {
                  final m = c.messages[index];
                  final mine = m.senderId == c.currentUid;
                  final time = m.createdAt != null
                      ? DateFormat.jm().format(m.createdAt!)
                      : 'Live';

                  return Align(
                    alignment:
                        mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: mine
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.senderName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(m.text),
                          const SizedBox(height: 2),
                          Text(time, style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Type message...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        c.sendThreadMessage(_msgCtrl.text);
                        _msgCtrl.clear();
                      },
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

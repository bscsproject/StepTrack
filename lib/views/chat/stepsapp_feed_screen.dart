import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:step_track/controller/suite_realtime_controller.dart';

class StepsAppFeedScreen extends StatefulWidget {
  static const String routeName = '/feed-suite';

  const StepsAppFeedScreen({super.key});

  @override
  State<StepsAppFeedScreen> createState() => _StepsAppFeedScreenState();
}

class _StepsAppFeedScreenState extends State<StepsAppFeedScreen> {
  final _postCtrl = TextEditingController();
  final _stepsCtrl = TextEditingController(text: '5000');

  @override
  void dispose() {
    _postCtrl.dispose();
    _stepsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SuiteRealtimeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('StepsApp Community Feed')),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share Step Update',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _postCtrl,
                      decoration: const InputDecoration(
                        hintText: 'How was your walk today?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _stepsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Steps',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: () async {
                            final steps =
                                int.tryParse(_stepsCtrl.text.trim()) ?? 0;
                            await c.publishFeedPost(_postCtrl.text, steps);
                            _postCtrl.clear();
                          },
                          child: const Text('Post'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...c.feedPosts.map((dynamic post) {
              final String authorName = (post.authorName ?? '').toString();
              final String badge = (post.badge ?? 'Walker').toString();
              final int stepsSnapshot = (post.stepsSnapshot ?? 0) as int;
              final String content = (post.content ?? '').toString();
              final bool likedByMe = (post.likedByMe ?? false) as bool;
              final int likesCount = (post.likesCount ?? 0) as int;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text(
                              authorName.isNotEmpty
                                  ? authorName[0].toUpperCase()
                                  : 'S',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$badge • ${NumberFormat.decimalPattern().format(stepsSnapshot)} steps',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(content),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              likedByMe
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                            ),
                            onPressed: () => c.toggleLikePost(post),
                          ),
                          Text('$likesCount'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
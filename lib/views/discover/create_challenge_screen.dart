import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/suite_realtime_controller.dart';

class CreateChallengeScreen extends StatefulWidget {
  static const String routeName = '/discover/create-challenge';

  const CreateChallengeScreen({super.key});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController(
    text: 'Daily step target synced in real time.',
  );
  final _targetCtrl = TextEditingController(text: '10000');
  String _category = 'community';
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SuiteRealtimeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Challenge')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Challenge Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Target Steps',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'community', child: Text('Community')),
              DropdownMenuItem(value: 'personal', child: Text('Personal')),
              DropdownMenuItem(value: 'plan', child: Text('Fitness Plan')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    final title = _titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    setState(() => _saving = true);
                    final target = int.tryParse(_targetCtrl.text.trim()) ?? 10000;
                    await c.createChallenge(
                      title: title,
                      category: _category,
                      description: _descCtrl.text,
                      targetSteps: target > 0 ? target : 10000,
                    );
                    setState(() => _saving = false);
                    Get.back();
                  },
            child: const Text('Save Challenge to Firestore'),
          ),
        ],
      ),
    );
  }
}

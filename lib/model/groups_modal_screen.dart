import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:step_track/controller/suite_realtime_controller.dart';


class GroupsModalScreen extends StatefulWidget {
  static const String routeName = '/discover/groups';

  const GroupsModalScreen({super.key});

  @override
  State<GroupsModalScreen> createState() => _GroupsModalScreenState();
}

class _GroupsModalScreenState extends State<GroupsModalScreen> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Sahiwal');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SuiteRealtimeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Step Groups')),
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
                      'Create New Group',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () async {
                        if (_nameCtrl.text.trim().isEmpty) return;
                        await c.createGroup(_nameCtrl.text, _cityCtrl.text);
                        _nameCtrl.clear();
                      },
                      child: const Text('Add Group'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...c.groups.map(
              (g) => Card(
                child: ListTile(
                  title: Text(g.name),
                  subtitle: Text(
                    '${g.city} • ${g.membersCount} members • ${NumberFormat.decimalPattern().format(g.weeklySteps)} steps',
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: () => c.toggleGroupJoin(g),
                    child: Text(g.isJoined ? 'Joined' : 'Join'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

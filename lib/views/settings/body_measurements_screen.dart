import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_track/controller/step_track_hub_controller.dart';
import 'package:step_track/model/step_track_hub_model.dart';
import 'package:step_track/themes/step_track_theme.dart';

class BodyMeasurementsScreen extends StatelessWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<StepTrackHubController>();

    return Obx(() {
      final p = ctrl.prefs.value;
      final m = p.measurements;
      final pal = StepTrackPalette.resolve(
        context,
        themeMode: p.themeMode,
        accent: Color(p.accentColorValue),
      );

      return Scaffold(
        backgroundColor: pal.screenBg,
        appBar: AppBar(
          backgroundColor: pal.screenBg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: pal.textPrimary),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Body Measurements',
            style: TextStyle(
              color: pal.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              leading: Icon(Icons.wc, color: pal.accent),
              title: Text('Sex', style: TextStyle(color: pal.textPrimary)),
              trailing: DropdownButton<String>(
                value: m.sex,
                dropdownColor: pal.elevatedBg,
                style: TextStyle(color: pal.textSecondary),
                underline: const SizedBox.shrink(),
                items: const ['Female', 'Male']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    ctrl.updateBodyMeasurements(m.copyWith(sex: val));
                  }
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.cake_outlined, color: pal.accent),
              title: Text(
                'Year of birth',
                style: TextStyle(color: pal.textPrimary),
              ),
              trailing: DropdownButton<int>(
                value: m.birthYear.clamp(1950, 2020),
                dropdownColor: pal.elevatedBg,
                style: TextStyle(color: pal.textSecondary),
                underline: const SizedBox.shrink(),
                items: List.generate(71, (i) => 1950 + i)
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    ctrl.updateBodyMeasurements(m.copyWith(birthYear: val));
                  }
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.monitor_weight_outlined, color: pal.accent),
              title: Text(
                'Body Weight',
                style: TextStyle(color: pal.textPrimary),
              ),
              trailing: Text(
                '${m.weightKg.toStringAsFixed(1)} kg',
                style: TextStyle(color: pal.textSecondary, fontSize: 15),
              ),
              onTap: () => _pickWeight(context, ctrl, m, pal),
            ),
            ListTile(
              leading: Icon(Icons.height, color: pal.accent),
              title: Text('Height', style: TextStyle(color: pal.textPrimary)),
              trailing: Text(
                '${m.heightCm} cm',
                style: TextStyle(color: pal.textSecondary, fontSize: 15),
              ),
              onTap: () => _pickHeight(context, ctrl, m, pal),
            ),
            ListTile(
              leading: Icon(Icons.straighten, color: pal.accent),
              title: Text(
                'Step Length',
                style: TextStyle(color: pal.textPrimary),
              ),
              trailing: Text(
                m.customStepLengthCm == null
                    ? 'Automatic'
                    : '${m.customStepLengthCm} cm',
                style: TextStyle(color: pal.textSecondary, fontSize: 15),
              ),
              onTap: () => ctrl.updateBodyMeasurements(
                m.copyWith(
                  clearCustomStepLength: m.customStepLengthCm != null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your body measurements are important for accurate steps, distance, and calories tracking.',
              style: TextStyle(color: pal.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    });
  }

  void _pickWeight(
    BuildContext context,
    StepTrackHubController ctrl,
    BodyMeasurementsModel m,
    StepTrackPalette pal,
  ) {
    final wholeCtrl = FixedExtentScrollController(
      initialItem: (m.weightKg.floor() - 30).clamp(0, 170),
    );
    final decCtrl = FixedExtentScrollController(
      initialItem: ((m.weightKg * 10).round() % 10).clamp(0, 9),
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: pal.elevatedBg,
      builder: (ctx) {
        var whole = (m.weightKg.floor()).clamp(30, 200);
        var dec = ((m.weightKg * 10).round() % 10).clamp(0, 9);
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      final w = whole + (dec / 10.0);
                      ctrl.updateBodyMeasurements(m.copyWith(weightKg: w));
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        controller: wholeCtrl,
                        itemExtent: 40,
                        onSelectedItemChanged: (i) => whole = 30 + i,
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 171,
                          builder: (_, i) => Center(
                            child: Text(
                              '${30 + i}',
                              style: TextStyle(color: pal.textPrimary),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        controller: decCtrl,
                        itemExtent: 40,
                        onSelectedItemChanged: (i) => dec = i,
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 10,
                          builder: (_, i) => Center(
                            child: Text(
                              '.$i kg',
                              style: TextStyle(color: pal.textPrimary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _pickHeight(
    BuildContext context,
    StepTrackHubController ctrl,
    BodyMeasurementsModel m,
    StepTrackPalette pal,
  ) {
    final hCtrl = FixedExtentScrollController(
      initialItem: (m.heightCm - 100).clamp(0, 130),
    );
    var selected = m.heightCm.clamp(100, 230);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: pal.elevatedBg,
      builder: (ctx) => SizedBox(
        height: 240,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    ctrl.updateBodyMeasurements(m.copyWith(heightCm: selected));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
            Expanded(
              child: ListWheelScrollView.useDelegate(
                controller: hCtrl,
                itemExtent: 40,
                onSelectedItemChanged: (i) => selected = 100 + i,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 131,
                  builder: (_, i) => Center(
                    child: Text(
                      '${100 + i} cm',
                      style: TextStyle(color: pal.textPrimary),
                    ),
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
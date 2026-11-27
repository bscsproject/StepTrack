import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:step_track/services/auth_service.dart';

class WeightScreen extends StatefulWidget {
  final double? currentWeightKg;
  final double? currentHeightCm;
  final VoidCallback? onSaved;

  const WeightScreen({
    super.key,
    this.currentWeightKg,
    this.currentHeightCm,
    this.onSaved,
  });

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  static const String _boxName = 'steptrack_auth_box';

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double? _weightKg;
  late double? _heightCm;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final cachedMetrics = _authService.getCachedSetupMetrics();

    final parsedWeight =
        widget.currentWeightKg ??
        double.tryParse(cachedMetrics?['weightKg']?.toString() ?? '');
    final parsedHeight =
        widget.currentHeightCm ??
        double.tryParse(cachedMetrics?['heightCm']?.toString() ?? '');

    _weightKg = (parsedWeight != null && parsedWeight > 0)
        ? double.parse(parsedWeight.toStringAsFixed(1))
        : null;
    _heightCm = (parsedHeight != null && parsedHeight > 0)
        ? parsedHeight
        : null;

    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedTime = TimeOfDay.fromDateTime(now);
  }

  double? get _calculatedBmi {
    if (_heightCm == null ||
        _heightCm! <= 0 ||
        _weightKg == null ||
        _weightKg! <= 0) {
      return null;
    }
    final hMeters = _heightCm! / 100.0;
    return _weightKg! / (hMeters * hMeters);
  }

  String get _bmiLabel {
    final bmi = _calculatedBmi;
    if (bmi == null) return 'BMI --';
    return 'BMI ${bmi.toStringAsFixed(1)}';
  }

  String get _formattedWeight {
    final weight = _weightKg;
    if (weight == null) return 'Add weight';
    final bool isWhole = (weight - weight.roundToDouble()).abs() < 0.05;
    return isWhole ? '${weight.round()} kg' : '${weight.toStringAsFixed(1)} kg';
  }

  String _formatDatePill(DateTime d) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dd = d.day.toString().padLeft(2, '0');
    return '$dd-${months[d.month - 1]}-${d.year}';
  }

  String _formatTimePill(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  void _adjustWeight(double delta) {
    setState(() {
      final current = _weightKg ?? 20.0;
      _weightKg = double.parse(
        (current + delta).clamp(20.0, 300.0).toStringAsFixed(1),
      );
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4FD0F8),
              onPrimary: Color(0xFF081016),
              surface: Color(0xFF141920),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4FD0F8),
              onPrimary: Color(0xFF081016),
              surface: Color(0xFF141920),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _editWeightAndHeightDialog() async {
    final wCtrl = TextEditingController(
      text: _weightKg == null
          ? ''
          : _weightKg!.toStringAsFixed(
              (_weightKg! - _weightKg!.roundToDouble()).abs() < 0.05 ? 0 : 1,
            ),
    );
    final hCtrl = TextEditingController(
      text: _heightCm != null ? _heightCm!.toStringAsFixed(0) : '',
    );

    await Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF151A22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Enter Weight & Height',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: wCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Weight (kg)',
                labelStyle: const TextStyle(color: Color(0xFF8E99A6)),
                filled: true,
                fillColor: const Color(0xFF0E1218),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Height (cm) for BMI',
                labelStyle: const TextStyle(color: Color(0xFF8E99A6)),
                filled: true,
                fillColor: const Color(0xFF0E1218),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8E99A6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final w = double.tryParse(wCtrl.text.trim());
              final heightText = hCtrl.text.trim();
              final h = heightText.isEmpty ? null : double.tryParse(heightText);
              if (w == null || w < 20 || w > 300) {
                Get.snackbar(
                  'Invalid weight',
                  'Enter a weight between 20 and 300 kg.',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              if (heightText.isNotEmpty && (h == null || h < 50 || h > 260)) {
                Get.snackbar(
                  'Invalid height',
                  'Enter a height between 50 and 260 cm.',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              setState(() {
                _weightKg = double.parse(w.toStringAsFixed(1));
                _heightCm = h ?? _heightCm;
              });
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FD0F8),
              foregroundColor: const Color(0xFF081016),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    wCtrl.dispose();
    hCtrl.dispose();
  }

  Future<void> _saveLoggedWeight() async {
    if (_isSaving) return;
    final weight = _weightKg;
    if (weight == null || weight <= 0) {
      Get.snackbar(
        'Weight required',
        'Enter your weight before saving.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!Hive.isBoxOpen(_boxName)) {
      Get.snackbar(
        'Storage unavailable',
        'Please reopen the app and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final loggedAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      final bmiVal = _calculatedBmi == null
          ? null
          : double.parse(_calculatedBmi!.toStringAsFixed(1));
      final currentUser = _authService.currentUser;
      final cached =
          (currentUser != null
              ? _authService.getCachedUserByUid(currentUser.uid)
              : null) ??
          _authService.getCachedUser();
      final uid = currentUser?.uid ?? cached?.uid ?? 'guest_user';
      final entryId = DateTime.now().microsecondsSinceEpoch.toString();
      final logData = <String, dynamic>{
        'id': entryId,
        'weightKg': weight,
        'heightCm': _heightCm,
        'bmi': bmiVal,
        'loggedAt': loggedAt.toIso8601String(),
      };

      await Hive.box(_boxName).put('weight_log_${uid}_$entryId', logData);
      await _authService.saveUserWeightMetrics(
        weightKg: weight,
        heightCm: _heightCm,
        loggedAt: loggedAt,
        bmi: bmiVal,
      );
      if (currentUser != null) {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('weight_logs')
            .doc(entryId)
            .set(logData);
      }

      widget.onSaved?.call();

      if (!mounted) return;
      Get.back();
      Get.snackbar(
        'Weight Logged',
        bmiVal == null
            ? '${weight.toStringAsFixed(1)} kg saved.'
            : '${weight.toStringAsFixed(1)} kg (BMI $bmiVal) saved.',
        backgroundColor: const Color(0xFF132632),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error, stackTrace) {
      debugPrint('Could not save weight entry: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        Get.snackbar(
          'Could not save weight',
          'Your weight could not be fully synced. Please try again.',
          backgroundColor: const Color(0xFF3B2020),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.65),
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF14181F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Sheet Handle
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D6672),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Close (X) + Title
                    SizedBox(
                      height: 36,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Get.back(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.close,
                                color: Color(0xFF8E99A6),
                                size: 24,
                              ),
                            ),
                          ),
                          const Text(
                            'Log Weight',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Weight + Live BMI Stepper Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C212A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => _adjustWeight(-1.0),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFF333A46),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.remove,
                                color: Color(0xFFB7C2CE),
                                size: 22,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _editWeightAndHeightDialog,
                            child: Column(
                              children: [
                                Text(
                                  _bmiLabel,
                                  style: const TextStyle(
                                    color: Color(0xFF8E99A6),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formattedWeight,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    height: 1.05,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _adjustWeight(1.0),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFF333A46),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Color(0xFFB7C2CE),
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Date & Time Picker Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C212A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _pickDate,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Date',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D333E),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _formatDatePill(_selectedDate),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFF282F3A)),
                          InkWell(
                            onTap: _pickTime,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Time',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D333E),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _formatTimePill(_selectedTime),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Primary CTA: Log Weight
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveLoggedWeight,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C2FF),
                          foregroundColor: const Color(0xFF071117),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF071117),
                                ),
                              )
                            : const Text(
                                'Log Weight',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

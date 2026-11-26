import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/auth_service.dart';

class EnableAutostartOnboardingScreen extends StatefulWidget {
  final int totalSteps;
  final int currentStep;
  final VoidCallback? onContinue;

  const EnableAutostartOnboardingScreen({
    super.key,
    this.totalSteps = 9,
    this.currentStep = 7,
    this.onContinue,
  });

  @override
  State<EnableAutostartOnboardingScreen> createState() =>
      _EnableAutostartOnboardingScreenState();
}

class _EnableAutostartOnboardingScreenState
    extends State<EnableAutostartOnboardingScreen> {
  final AuthService _authService = AuthService();
  bool _isSaving = false;
  bool _settingsOpened = false;

  Future<void> _onOpenSettingsPressed() async {
    _settingsOpened = true;
    await _authService.saveAutostartStatus(
      autostartSettingsOpened: true,
      actionSource: 'open_settings',
    );
    await openAppSettings();
  }

  Future<void> _onContinuePressed() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await _authService.saveAutostartStatus(
        autostartSettingsOpened: _settingsOpened,
        actionSource: 'continue',
      );

      if (widget.onContinue != null) {
        widget.onContinue!();
      } else {
        Get.snackbar(
          'Autostart Saved',
          'Aapki autostart preference save ho gayi hai.',
          backgroundColor: const Color(0xFF15222B),
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
      backgroundColor: const Color(0xFF080A0C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
          child: Column(
            children: [
              // 1. Top Segmented Onboarding Progress Bars
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Row(
                  children: List.generate(widget.totalSteps, (index) {
                    final bool isActive = index <= widget.currentStep;
                    return Expanded(
                      child: Container(
                        height: 4.5,
                        margin: EdgeInsets.only(
                          right: index == widget.totalSteps - 1 ? 0 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF19A7E6)
                              : const Color(0xFF1B2026),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const Spacer(flex: 3),

              // 2. Circular Green Arrow Ring with White Walker Icon
              SizedBox(
                width: 146,
                height: 146,
                child: CustomPaint(
                  painter: _AutostartRingPainter(),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.directions_walk,
                        color: Colors.white,
                        size: 62,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // 3. Title: "Enable Autostart"
              const Text(
                'Enable Autostart',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 14),

              // 4. Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  'Automatically start StepTrack when\nyou restart your phone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7D858E),
                    fontSize: 17,
                    height: 1.38,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              const Spacer(flex: 4),

              // 5. "Open settings" Link Button
              TextButton(
                onPressed: _onOpenSettingsPressed,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4FD0F8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'Open settings',
                  style: TextStyle(
                    color: Color(0xFF4FD0F8),
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 6. Bottom Cyan "Continue" Pill Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _onContinuePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FD0F8),
                    foregroundColor: const Color(0xFF0A1014),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF0A1014),
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0A1014),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Painter for Green Circular Ring with Top-Left Arrowhead
class _AutostartRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.41;
    const strokeWidth = 10.0;

    final trackPaint = Paint()
      ..color = const Color(0xFF23282E)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final greenArcPaint = Paint()
      ..color = const Color(0xFF35D41B)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Subtle dark track
    canvas.drawCircle(center, radius, trackPaint);

    // Bright green arc starting near top-left arrow and sweeping clockwise
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -1.75, 5.45, false, greenArcPaint);

    // Top-left pointing arrowhead
    const arrowTip = Offset(44, 24);
    final arrowPath = Path()
      ..moveTo(arrowTip.dx - 11, arrowTip.dy + 2)
      ..lineTo(arrowTip.dx + 10, arrowTip.dy - 10)
      ..lineTo(arrowTip.dx + 8, arrowTip.dy + 13)
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = const Color(0xFF35D41B)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
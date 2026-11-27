import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/auth_service.dart';

class BatteryOptimisationOnboardingScreen extends StatefulWidget {
  final int totalSteps;
  final int currentStep;
  final VoidCallback? onContinue;

  const BatteryOptimisationOnboardingScreen({
    super.key,
    this.totalSteps = 8,
    this.currentStep = 5,
    this.onContinue,
  });

  @override
  State<BatteryOptimisationOnboardingScreen> createState() =>
      _BatteryOptimisationOnboardingScreenState();
}

class _BatteryOptimisationOnboardingScreenState
    extends State<BatteryOptimisationOnboardingScreen> {
  final AuthService _authService = AuthService();
  bool _isRequesting = false;

  Future<void> _requestBatteryOptimisationAndContinue() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);

    try {
      PermissionStatus status =
          await Permission.ignoreBatteryOptimizations.status;

      if (!status.isGranted) {
        status = await Permission.ignoreBatteryOptimizations.request();
      }

      final bool isGranted = status.isGranted;

      await _authService.saveBatteryOptimisationStatus(
        isIgnoringBatteryOptimisations: isGranted,
        permissionStatus: status.name,
      );

      if (!mounted) return;
      if (widget.onContinue != null) {
        widget.onContinue!();
      } else {
        Get.snackbar(
          isGranted ? 'Background Ready' : 'Saved',
          isGranted
              ? 'Battery optimisation allow ho gayi hai. Background step tracking behtar rahegi.'
              : 'Aapki preference save ho gayi hai.',
          backgroundColor: const Color(0xFF15222B),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Battery optimisation error: $e');
      if (mounted) {
        Get.snackbar(
          'Battery Setting Error',
          'Battery optimisation save karte waqt masla aaya.',
          backgroundColor: const Color(0xFF28181D),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int safeTotal = widget.totalSteps > 0 ? widget.totalSteps : 8;
    final int safeStep = widget.currentStep.clamp(0, safeTotal - 1);

    return Scaffold(
      backgroundColor: const Color(0xFF080A0C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
          child: Column(
            children: [
              // 1. Top Segmented Onboarding Progress Bars (8 steps consistent)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Row(
                  children: List.generate(safeTotal, (index) {
                    final bool isActive = index <= safeStep;
                    return Expanded(
                      child: Container(
                        height: 4.5,
                        margin: EdgeInsets.only(
                          right: index == safeTotal - 1 ? 0 : 8,
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

              // 2. Battery Icon Graphic
              SizedBox(
                width: 120,
                height: 150,
                child: CustomPaint(
                  painter: _BatteryOptimisationPainter(),
                ),
              ),

              const SizedBox(height: 28),

              // 3. Title: "Battery optimisation"
              const Text(
                'Battery optimisation',
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
                  "This makes sure that StepTrack can\ncount your steps when you don't have\nthe app open.",
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

              // 5. Bottom Cyan "Continue" Pill Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isRequesting
                      ? null
                      : _requestBatteryOptimisationAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FD0F8),
                    foregroundColor: const Color(0xFF0A1014),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isRequesting
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

/// Custom Painter for White Battery Outline + Dark Green Top + Bright Green Fill
class _BatteryOptimisationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final capPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final bodyOutlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5;

    final emptyTopPaint = Paint()
      ..color = const Color(0xFF1A3A14)
      ..style = PaintingStyle.fill;

    final chargedFillPaint = Paint()
      ..color = const Color(0xFF35D41B)
      ..style = PaintingStyle.fill;

    final double capWidth = size.width * 0.34;
    final double capHeight = size.height * 0.085;
    final double capLeft = (size.width - capWidth) / 2;

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(capLeft, size.height * 0.05, capWidth, capHeight),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      ),
      capPaint,
    );

    final double bodyTop = size.height * 0.145;
    final double bodyLeft = size.width * 0.21;
    final double bodyWidth = size.width * 0.58;
    final double bodyHeight = size.height * 0.78;

    final RRect outerBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(bodyLeft, bodyTop, bodyWidth, bodyHeight),
      const Radius.circular(18),
    );

    const double inset = 6.5;
    final RRect innerClip = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        bodyLeft + inset,
        bodyTop + inset,
        bodyWidth - inset * 2,
        bodyHeight - inset * 2,
      ),
      const Radius.circular(13),
    );

    canvas.save();
    canvas.clipRRect(innerClip);

    canvas.drawRect(
      Rect.fromLTWH(
        bodyLeft + inset,
        bodyTop + inset,
        bodyWidth - inset * 2,
        (bodyHeight - inset * 2) * 0.26,
      ),
      emptyTopPaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        bodyLeft + inset,
        bodyTop + inset + (bodyHeight - inset * 2) * 0.26,
        bodyWidth - inset * 2,
        (bodyHeight - inset * 2) * 0.74,
      ),
      chargedFillPaint,
    );

    canvas.restore();
    canvas.drawRRect(outerBody, bodyOutlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
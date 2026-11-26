import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class MotionSensorOnboardingScreen extends StatefulWidget {
  final int totalSteps;
  final int currentStep;
  final VoidCallback? onPermissionGranted;

  const MotionSensorOnboardingScreen({
    super.key,
    this.totalSteps = 9,
    this.currentStep = 0,
    this.onPermissionGranted, required void Function() onContinue,
  });

  @override
  State<MotionSensorOnboardingScreen> createState() =>
      _MotionSensorOnboardingScreenState();
}

class _MotionSensorOnboardingScreenState
    extends State<MotionSensorOnboardingScreen> {
  bool _isRequesting = false;

  Future<void> _requestMotionPermission() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);

    try {
      PermissionStatus status = await Permission.activityRecognition.status;

      if (status.isDenied) {
        status = await Permission.activityRecognition.request();
      }

      if (status.isGranted || status.isLimited) {
        if (widget.onPermissionGranted != null) {
          widget.onPermissionGranted!();
        } else {
          Get.snackbar(
            'Permission Granted',
            'Motion Sensor / Activity Recognition active ho gaya hai.',
            backgroundColor: const Color(0xFF15222B),
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else if (status.isPermanentlyDenied) {
        Get.snackbar(
          'Permission Required',
          'Settings mein ja kar Physical Activity / Motion Sensor permission allow karein.',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          mainButton: TextButton(
            onPressed: () => openAppSettings(),
            child: const Text(
              'Open Settings',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      } else {
        Get.snackbar(
          'Permission Denied',
          'Steps count karne ke liye Motion Sensor permission zaroori hai.',
          backgroundColor: const Color(0xFF15222B),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D10),
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
                    final bool isActive = index == widget.currentStep;
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

              // 2. Green Rounded Badge with Running Figure & Speed Lines
              Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  color: const Color(0xFF35D41B),
                  borderRadius: BorderRadius.circular(36),
                ),
                child: CustomPaint(
                  painter: _RunnerBadgePainter(),
                ),
              ),

              const SizedBox(height: 30),

              // 3. Title: "Motion Sensor"
              const Text(
                'Motion Sensor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 14),

              // 4. Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  'To count your steps, we need your\npermission to access activity\nrecognition.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7D858E),
                    fontSize: 16.5,
                    height: 1.38,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              const Spacer(flex: 4),

              // 5. Bottom Cyan Pill Button: "Allow Motion Sensor"
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isRequesting ? null : _requestMotionPermission,
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
                          'Allow Motion Sensor',
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

/// Custom Painter for White Running Person + Left Speed Lines inside Green Badge
class _RunnerBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Speed lines on the left (lighter green)
    final speedPaint = Paint()
      ..color = const Color(0xFF7BE668)
      ..strokeWidth = 7.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.24, size.height * 0.44),
      Offset(size.width * 0.43, size.height * 0.44),
      speedPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.19, size.height * 0.54),
      Offset(size.width * 0.40, size.height * 0.54),
      speedPaint,
    );

    // Head
    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.24),
      size.width * 0.068,
      whitePaint,
    );

    // Torso
    strokePaint.strokeWidth = 12;
    canvas.drawLine(
      Offset(size.width * 0.58, size.height * 0.34),
      Offset(size.width * 0.49, size.height * 0.56),
      strokePaint,
    );

    // Front Arm (reaching forward/up)
    strokePaint.strokeWidth = 9.5;
    final frontArm = Path()
      ..moveTo(size.width * 0.57, size.height * 0.37)
      ..lineTo(size.width * 0.71, size.height * 0.41)
      ..lineTo(size.width * 0.78, size.height * 0.35);
    canvas.drawPath(frontArm, strokePaint);

    // Back Arm
    final backArm = Path()
      ..moveTo(size.width * 0.55, size.height * 0.38)
      ..lineTo(size.width * 0.43, size.height * 0.46);
    canvas.drawPath(backArm, strokePaint);

    // Front Leg (striding forward)
    strokePaint.strokeWidth = 11.5;
    final frontLeg = Path()
      ..moveTo(size.width * 0.49, size.height * 0.56)
      ..lineTo(size.width * 0.63, size.height * 0.63)
      ..lineTo(size.width * 0.67, size.height * 0.79);
    canvas.drawPath(frontLeg, strokePaint);

    // Back Leg (pushing off)
    final backLeg = Path()
      ..moveTo(size.width * 0.49, size.height * 0.56)
      ..lineTo(size.width * 0.36, size.height * 0.67)
      ..lineTo(size.width * 0.27, size.height * 0.77);
    canvas.drawPath(backLeg, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
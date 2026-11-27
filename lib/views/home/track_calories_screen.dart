import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackCaloriesScreen extends StatefulWidget {
  final String playStoreUrl;
  final bool autoOpenPlayStore;

  const TrackCaloriesScreen({
    super.key,
    this.playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.google.android.apps.fitness',
    this.autoOpenPlayStore = true,
  });

  @override
  State<TrackCaloriesScreen> createState() => _TrackCaloriesScreenState();
}

class _TrackCaloriesScreenState extends State<TrackCaloriesScreen> {
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoOpenPlayStore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openPlayStore();
      });
    }
  }

  Future<void> _openPlayStore() async {
    if (_isLaunching) return;
    setState(() => _isLaunching = true);

    try {
      final uri = Uri.parse(widget.playStoreUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        Get.snackbar(
          'Play Store',
          'Play Store open nahi ho saka. Dobara try karein.',
          backgroundColor: const Color(0xFF15222B),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLaunching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06080A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF06080A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Track Calories'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF10151C),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF19222E)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E252E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFFF6D1F),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'CalApp: AI Calorie Tracker',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Effortlessly track calories with our AI-powered calorie tracker on Google Play.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF8E99A6),
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLaunching ? null : _openPlayStore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FD0F8),
                    foregroundColor: const Color(0xFF081016),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _isLaunching
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF081016),
                          ),
                        )
                      : const Text(
                          'Open in Google Play',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
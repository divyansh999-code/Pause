import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pause/core/theme.dart';
import 'package:pause/models/pause_models.dart';
import 'package:pause/services/storage_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:installed_apps/installed_apps.dart';
import 'package:pause/services/accessibility_service.dart';

class PauseOverlay extends StatefulWidget {
  final bool isTestMode;
  final String packageName;
  const PauseOverlay({super.key, this.isTestMode = false, this.packageName = 'Unknown'});

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay> {
  final TextEditingController _controller = TextEditingController();
  bool _canProceed = false;
  String _activePackage = 'Unknown';

  final List<String> _questions = [
    "Why do you want to open this app right now?",
    "What are you hoping to find here?",
    "Is there something better you could be doing?",
    "What emotion is making you reach for this app?",
    "Will opening this app help you or just waste time?",
  ];

  late String _currentQuestion;

  @override
  void initState() {
    super.initState();
    _activePackage = widget.packageName;
    _currentQuestion = (_questions..shuffle()).first;
    _controller.addListener(_validateInput);

    if (!widget.isTestMode && _activePackage == 'Unknown') {
      _loadActivePackage();
    }
  }

  Future<void> _loadActivePackage() async {
    final pkg = await StorageService.getActiveOverlayPackage();
    if (pkg != null && mounted) {
      setState(() {
        _activePackage = pkg;
      });
    }
  }

  void _validateInput() {
    setState(() {
      _canProceed = _controller.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.wind, color: AppTheme.primaryColor, size: 64),
                  const SizedBox(height: 48),
                  Text(
                    'Mindful Pause',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _currentQuestion,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _controller,
                    maxLines: 4,
                    autofocus: true,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your reflection here...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      counterStyle: TextStyle(
                        color: _canProceed ? Colors.green : Colors.white24,
                        fontWeight: _canProceed ? FontWeight.bold : FontWeight.normal,
                      ),
                      counterText: '${_controller.text.length}',
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        FilledButton(
          onPressed: _canProceed
              ? () async {
                  try {
                    StorageService.savePauseLog(PauseLog(
                      timestamp: DateTime.now(),
                      packageName: _activePackage,
                      reflection: _controller.text,
                      choiceToProceed: false,
                    ));
                    FlutterOverlayWindow.shareData("reset_cooldown:$_activePackage");
                  } catch (e) {

                    debugPrint("Error in skip button: $e");
                  }
                  
                  _controller.clear();
                  if (widget.isTestMode) {
                    Navigator.pop(context);
                  } else {
                    await FlutterOverlayWindow.closeOverlay();
                    try {
                      InstalledApps.startApp('com.antigravity.pause');
                    } catch (_) {}
                  }
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.black87,
            disabledBackgroundColor: Colors.white.withOpacity(0.1),
            disabledForegroundColor: Colors.white54,
          ),
          child: const Text("I'll skip it"),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _canProceed
              ? () async {
                  try {
                    StorageService.savePauseLog(PauseLog(
                      timestamp: DateTime.now(),
                      packageName: _activePackage,
                      reflection: _controller.text,
                      choiceToProceed: true,
                    ));
                    FlutterOverlayWindow.shareData("unlock:$_activePackage");
                  } catch (e) {

                    debugPrint("Error in open button: $e");
                  }

                  _controller.clear();
                  if (widget.isTestMode) {
                    Navigator.pop(context);
                  } else {
                    await FlutterOverlayWindow.closeOverlay();
                  }
                }
              : null,
          child: Text(
            'Open anyway',
            style: GoogleFonts.outfit(
              color: _canProceed ? Colors.white54 : Colors.white12,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

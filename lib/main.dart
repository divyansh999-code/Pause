import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pause/app.dart';
import 'package:pause/screens/overlay/pause_overlay.dart';
import 'package:pause/services/accessibility_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start the accessibility service listener.
  // Note: This only works if permission is granted.
  if (!kIsWeb && Platform.isAndroid) {
    AccessibilityHandler.startListening();
  }

  runApp(
    const ProviderScope(
      child: PauseApp(),
    ),
  );
}

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(
    const ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: PauseOverlay(),
      ),
    ),
  );
}

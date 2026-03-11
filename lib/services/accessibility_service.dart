import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:pause/services/storage_service.dart';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AccessibilityHandler {
  static const _channel = MethodChannel('com.antigravity.pause/accessibility');
  static bool _isListening = false;

  static void startListening() async {
    if (kIsWeb || !Platform.isAndroid) {
      developer.log('AccessibilityHandler: Skipping listener - Not on Android.');
      return;
    }

    if (_isListening) return;
    _isListening = true;

    developer.log('AccessibilityHandler: startListening() triggered');

    // Initial sync of monitored apps
    await updateMonitoredApps();

    FlutterOverlayWindow.overlayListener.listen((event) {
      developer.log('AccessibilityHandler: Received overlay message: $event');
      if (event is String && event.startsWith('unlock:')) {
        final pkg = event.substring(7);
        developer.log('AccessibilityHandler: Processing unlock for $pkg from overlay');
        unlockPackage(pkg);
      } else if (event is String && event.startsWith('reset_cooldown:')) {
        final pkg = event.substring(15);
        developer.log('AccessibilityHandler: Processing reset cooldown for $pkg from overlay');
        resetCooldown(pkg);
      }
    });

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onAppOpened':
          developer.log('Native Accessibility Event: App Opened -> ${call.arguments}');
          break;
        case 'triggerOverlay':
          final String packageName = call.arguments;
          developer.log('Native triggerOverlay received for: $packageName');
          _handleTriggerOverlay(packageName);
          break;
        default:
          developer.log('Unknown method from native: ${call.method}');
      }
    });

    developer.log('AccessibilityHandler: MethodChannel listener successfully attached.');
  }

  static Future<void> updateMonitoredApps() async {
    try {
      final monitoredApps = await StorageService.getMonitoredApps();
      final packageNames = monitoredApps.map((app) => app.packageName).toList();
      await _channel.invokeMethod('updateMonitoredApps', packageNames);
      developer.log('AccessibilityHandler: Updated monitored apps in Native: $packageNames');
    } catch (e) {
      developer.log('AccessibilityHandler: Error updating monitored apps: $e');
    }
  }

  static Future<void> _handleTriggerOverlay(String packageName) async {
    developer.log('Accessibility Handler: Starting _handleTriggerOverlay for: $packageName');

    // Avoid self-triggering
    if (packageName == 'com.antigravity.pause') {
      developer.log('Accessibility Handler: Pause app itself detected. Ignoring.');
      return;
    }

    // 1. Check Overlay Permission
    bool hasOverlayPermission = await FlutterOverlayWindow.isPermissionGranted();
    developer.log('Accessibility Handler: Overlay permission status: $hasOverlayPermission');
    
    if (!hasOverlayPermission) {
      developer.log('Accessibility Handler: ABORTING - Overlay permission NOT granted.');
      return;
    }

    // 2. Check if overlay is already active
    bool isShowing = await FlutterOverlayWindow.isActive();
    developer.log('Accessibility Handler: Is overlay already active? $isShowing');
    
    if (!isShowing) {
      developer.log('Accessibility Handler: EXECUTION REACHED - Calling FlutterOverlayWindow.showOverlay()...');
      try {
        await StorageService.setActiveOverlayPackage(packageName);
        await FlutterOverlayWindow.showOverlay(
          enableDrag: false,
          overlayTitle: "Pause",
          overlayContent: "Mindful Reflection",
          flag: OverlayFlag.focusPointer,
          alignment: OverlayAlignment.center,
          visibility: NotificationVisibility.visibilityPublic,
          positionGravity: PositionGravity.none,
          width: WindowSize.matchParent,
          height: WindowSize.fullCover,
          startPosition: const OverlayPosition(0, 0),
        );
        developer.log('Accessibility Handler: showOverlay call COMPLETED successfully.');
      } catch (e, stack) {
        developer.log('Accessibility Handler: ERROR during showOverlay: $e');
        developer.log('Stacktrace: $stack');
      }
    } else {
      developer.log('Accessibility Handler: Overlay is already showing. skipping showOverlay.');
    }
  }

  static Future<bool> isPermissionEnabled() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    // We can use a simple check via the channel or just return true for now 
    // since the native service will only send events if it's enabled.
    // However, the UI might need to know if it should show the "Enable" button.
    // For now, let's keep it simple or implement a native check.
    try {
      final bool? isEnabled = await _channel.invokeMethod('isServiceEnabled');
      return isEnabled ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> resetCooldown(String packageName) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('resetCooldown', packageName);
    } catch (e) {
      developer.log('AccessibilityHandler: Error resetting cooldown: $e');
    }
  }

  static Future<void> unlockPackage(String packageName) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('unlockPackage', packageName);
    } catch (e) {
      developer.log('AccessibilityHandler: Error unlocking package: $e');
    }
  }

  static Future<void> requestPermission() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (e) {
      developer.log('AccessibilityHandler: Error requesting permission: $e');
    }
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import 'package:pause/models/pause_models.dart';
import 'dart:convert';

class StorageService {
  static const String _appsKey = 'monitored_apps';
  static const String _migrationKey = 'data_cleared_v2';

  static Future<void> saveMonitoredApps(List<MonitoredApp> apps) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encoded = apps.map((a) => jsonEncode(a.toMap())).toList();
    await prefs.setStringList(_appsKey, encoded);
  }

  static Future<List<MonitoredApp>> getMonitoredApps() async {
    final prefs = await SharedPreferences.getInstance();

    // One-time migration to clear old hardcoded apps
    if (prefs.getBool(_migrationKey) != true) {
      await prefs.remove(_appsKey);
      await prefs.setBool(_migrationKey, true);
    }

    final List<String>? data = prefs.getStringList(_appsKey);
    if (data == null) return [];
    
    return data.map((s) => MonitoredApp.fromMap(jsonDecode(s))).toList();
  }

  static const String _logsKey = 'pause_logs';

  static Future<void> savePauseLog(PauseLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PauseLog> currentLogs = await getPauseLogs();
    final List<PauseLog> updatedLogs = [log, ...currentLogs];
    final List<String> encoded = updatedLogs.map((l) => jsonEncode(l.toMap())).toList();
    await prefs.setStringList(_logsKey, encoded);
  }

  static Future<List<PauseLog>> getPauseLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? data = prefs.getStringList(_logsKey);
    if (data == null) return [];
    return data.map((s) => PauseLog.fromMap(jsonDecode(s))).toList();
  }

  static const String _activePkgKey = 'active_overlay_pkg';

  static Future<void> setActiveOverlayPackage(String pkg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activePkgKey, pkg);
  }

  static Future<String?> getActiveOverlayPackage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getString(_activePkgKey);
  }
}

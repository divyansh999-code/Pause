class MonitoredApp {
  final String name;
  final String packageName;
  final bool isEnabled;

  MonitoredApp({
    required this.name,
    required this.packageName,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'packageName': packageName,
      'isEnabled': isEnabled ? 1 : 0,
    };
  }

  factory MonitoredApp.fromMap(Map<String, dynamic> map) {
    return MonitoredApp(
      name: map['name'],
      packageName: map['packageName'],
      isEnabled: map['isEnabled'] == 1,
    );
  }
}

class PauseLog {
  final DateTime timestamp;
  final String packageName;
  final String reflection;
  final bool choiceToProceed;

  PauseLog({
    required this.timestamp,
    required this.packageName,
    required this.reflection,
    required this.choiceToProceed,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'packageName': packageName,
      'reflection': reflection,
      'choiceToProceed': choiceToProceed ? 1 : 0,
    };
  }

  factory PauseLog.fromMap(Map<String, dynamic> map) {
    return PauseLog(
      timestamp: DateTime.parse(map['timestamp']),
      packageName: map['packageName'],
      reflection: map['reflection'],
      choiceToProceed: map['choiceToProceed'] == 1,
    );
  }
}

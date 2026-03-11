import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pause/core/theme.dart';
import 'package:pause/screens/insights_screen.dart';
import 'package:pause/services/accessibility_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:pause/models/pause_models.dart';
import 'package:pause/services/storage_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:pause/screens/overlay/pause_overlay.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  bool _isServiceEnabled = false;
  List<MonitoredApp> _monitoredApps = [];
  int _pauseCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkServiceStatus();
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkServiceStatus();
      _loadData();
    }
  }

  Future<void> _loadData() async {
    await _loadMonitoredApps();
    await _loadPauseCount();
  }

  Future<void> _loadPauseCount() async {
    final logs = await StorageService.getPauseLogs();
    final today = logs.where((l) => l.timestamp.day == DateTime.now().day).length;
    setState(() {
      _pauseCount = today;
    });
  }

  Future<void> _loadMonitoredApps() async {
    final apps = await StorageService.getMonitoredApps();
    setState(() {
      _monitoredApps = apps;
    });
    // Sync with Native
    await AccessibilityHandler.updateMonitoredApps();
  }

  Future<void> _checkServiceStatus() async {
    final accessibility = await AccessibilityHandler.isPermissionEnabled();
    final overlay = await FlutterOverlayWindow.isPermissionGranted();
    setState(() {
      _isServiceEnabled = accessibility && overlay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      Text(
                        'Pause',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stay mindful of your time.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 48),
                      _buildServiceToggle(),
                      const SizedBox(height: 32),
                      _buildMonitoredAppsSection(),
                      const Spacer(),
                      const SizedBox(height: 32),
                      _buildInsightsSummary(),
                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          'Made by Divyansh Khandal',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.white60,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildServiceToggle() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isServiceEnabled
              ? AppTheme.primaryColor.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isServiceEnabled ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
            color: _isServiceEnabled ? AppTheme.primaryColor : Colors.white24,
            size: 32,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mindfulness Service',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  (kIsWeb || !Platform.isAndroid)
                      ? 'Feature not available on this platform'
                      : (_isServiceEnabled ? 'Active and protecting' : 'Required for detection'),
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isServiceEnabled,
            onChanged: (kIsWeb || !Platform.isAndroid)
                ? null
                : (val) async {
                    // Unconditionally request accessibility permission to open settings
                    await AccessibilityHandler.requestPermission();
                    if (val) {
                      // Request Overlay only if trying to enable
                      if (!await FlutterOverlayWindow.isPermissionGranted()) {
                        await FlutterOverlayWindow.requestPermission();
                      }
                    }
                    _checkServiceStatus();
                  },
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoredAppsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monitored Apps',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: _showAddAppDialog,
              icon: const Icon(LucideIcons.plusCircle, color: AppTheme.primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._monitoredApps.map((app) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAppItem(app),
            )),
      ],
    );
  }

  void _showAddAppDialog() {
    showDialog(
      context: context,
      builder: (context) => AppPickerDialog(
        onAppSelected: (app) async {
          final isAlreadyAdded = _monitoredApps.any((a) => a.packageName == app.packageName);
          if (!isAlreadyAdded) {
            final newApp = MonitoredApp(name: app.name!, packageName: app.packageName!);
            final updatedList = [..._monitoredApps, newApp];
            await StorageService.saveMonitoredApps(updatedList);
            _loadData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('App already in monitored list')),
            );
          }
        },
      ),
    );
  }

  void _showRemoveAppDialog(MonitoredApp app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text('Remove App', style: GoogleFonts.outfit(color: Colors.white)),
        content: Text(
          'Remove ${app.name} from monitored apps?',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final updatedList = _monitoredApps
                  .where((a) => a.packageName != app.packageName)
                  .toList();
              await StorageService.saveMonitoredApps(updatedList);
              _loadData();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppItem(MonitoredApp app) {
    return InkWell(
      onLongPress: () => _showRemoveAppDialog(app),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            FutureBuilder<AppInfo?>(
              future: InstalledApps.getAppInfo(app.packageName, BuiltWith.flutter),
              builder: (context, snapshot) {
                final appInfo = snapshot.data;
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: appInfo?.icon != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(appInfo!.icon!, fit: BoxFit.cover),
                        )
                      : const Icon(LucideIcons.appWindow, size: 24, color: Colors.white38),
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    app.packageName,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSummary() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.2),
            AppTheme.primaryColor.withOpacity(0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const InsightsScreen()));
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles, color: AppTheme.primaryColor, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_pauseCount Mindful Pauses today',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const Text(
                        'You saved 45 minutes of screen time.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.arrowRight, color: AppTheme.primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppPickerDialog extends StatefulWidget {
  final Function(AppInfo) onAppSelected;
  const AppPickerDialog({super.key, required this.onAppSelected});

  @override
  State<AppPickerDialog> createState() => _AppPickerDialogState();
}

class _AppPickerDialogState extends State<AppPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<AppInfo> _allApps = [];
  List<AppInfo> _filteredApps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await InstalledApps.getInstalledApps(true, true, '');

    // Strict filter list
    final List<String> excludedPrefixes = [
      "com.android",
      "com.oplus",
      "com.qualcomm",
      "com.mediatek",
      "com.google.android",
      "com.coloros",
      "com.realme",
      "com.heytap",
      "com.nearme",
    ];

    final filtered = apps.where((app) {
      final pkg = app.packageName ?? "";
      
      // Exception: Always keep YouTube
      if (pkg == "com.google.android.youtube") return true;

      // Exclude if it starts with any of the prefixes
      for (final prefix in excludedPrefixes) {
        if (pkg.startsWith(prefix)) return false;
      }

      return true;
    }).toList();

    // Sort alphabetically by app name
    filtered.sort((a, b) =>
        (a.name ?? "").toLowerCase().compareTo((b.name ?? "").toLowerCase()));

    if (mounted) {
      setState(() {
        _allApps = filtered;
        _filteredApps = filtered;
        _isLoading = false;
      });
    }
  }

  void _filterApps(String query) {
    setState(() {
      _filteredApps = _allApps
          .where((app) =>
              (app.name ?? "").toLowerCase().contains(query.toLowerCase()) ||
              (app.packageName ?? "").toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      title: Text('Select App to Monitor',
          style: GoogleFonts.outfit(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _filterApps,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search apps...',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.search, color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : _filteredApps.isEmpty
                      ? const Center(
                          child: Text('No apps found',
                              style: TextStyle(color: Colors.white24)))
                      : ListView.builder(
                          itemCount: _filteredApps.length,
                          itemBuilder: (context, index) {
                            final app = _filteredApps[index];
                            return ListTile(
                              leading: app.icon != null
                                  ? Image.memory(app.icon!, width: 32, height: 32)
                                  : const Icon(Icons.apps, color: Colors.white24),
                              title: Text(app.name ?? "Unknown",
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text(app.packageName ?? "Unknown",
                                  style: const TextStyle(
                                      color: Colors.white24, fontSize: 10)),
                              onTap: () {
                                widget.onAppSelected(app);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

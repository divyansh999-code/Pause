import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pause/core/theme.dart';

import 'package:pause/models/pause_models.dart';
import 'package:pause/services/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  List<PauseLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await StorageService.getPauseLogs();
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Insights', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildStatCard(context),
                  const SizedBox(height: 32),
                  Text(
                    'Reflection History',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadLogs,
                      color: AppTheme.primaryColor,
                      backgroundColor: AppTheme.surfaceColor,
                      child: _logs.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.4,
                                  child: Center(
                                    child: Text(
                                      'No reflections yet. Take a pause!',
                                      style: GoogleFonts.outfit(color: Colors.white24),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _buildHistoryList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(BuildContext context) {
    final today = _logs.where((l) => l.timestamp.day == DateTime.now().day).length;
    final weekly = _logs.where((l) => l.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 7)))).length;
    final total = _logs.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(today.toString(), 'Today'),
          _buildStatItem(weekly.toString(), 'Weekly'),
          _buildStatItem(total.toString(), 'Total'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return FutureBuilder<AppInfo?>(
          future: InstalledApps.getAppInfo(log.packageName, BuiltWith.flutter),
          builder: (context, snapshot) {
            final appName = snapshot.data?.name ?? log.packageName.split('.').last;
            return _buildHistoryItem(
              appName,
              DateFormat('MMM d, h:mm a').format(log.timestamp),
              '“${log.reflection}”',
              log.choiceToProceed,
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryItem(String app, String time, String quote, bool proceeded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: proceeded ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                app,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white70),
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 12, color: Colors.white24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            quote,
            style: GoogleFonts.outfit(
              fontStyle: FontStyle.italic,
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            proceeded ? 'Proceeded anyway' : 'Stopped for reflection',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: proceeded ? Colors.redAccent.withOpacity(0.5) : AppTheme.primaryColor.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

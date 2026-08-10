//flutter_app/lib/screens/dashboard/record_health_screen.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/auth_manager.dart';
import '../../core/services/health_service.dart'; // ← IMPORTANT

class RecordHealthScreen extends StatefulWidget {
  final String token;

  const RecordHealthScreen({super.key, required this.token});

  @override
  State<RecordHealthScreen> createState() => _RecordHealthScreenState();
}

class _RecordHealthScreenState extends State<RecordHealthScreen> {
  bool isLoading = true;
  bool isSyncing = false;
  List<Map<String, dynamic>> records = [];
  String? errorMessage;
  int currentPage = 1;
  int totalPages = 1;
  final int limit = 30;

  // ─── Google Health connection status ───────────────────────────────────────
  bool googleHealthConnected = false;
  String? googleHealthEmail;
  String? googleHealthPlatform;
  String? lastSyncError;
  List<String> debugLogs = [];

  @override
  void initState() {
    super.initState();
    _checkGoogleHealthStatus();
    loadRecords();
  }

  // ─── Debug helper ──────────────────────────────────────────────────────────
  void _addLog(String message) {
    final time = DateFormat('HH:mm:ss').format(DateTime.now());
    setState(() {
      debugLogs.insert(0, '[$time] $message');
      if (debugLogs.length > 40) debugLogs.removeLast();
    });
    debugPrint('[RecordHealthScreen] $message');
  }

  // ─── Check if Google Health is connected ───────────────────────────────────
  Future<void> _checkGoogleHealthStatus() async {
    final info = HealthService.connectionInfo;
    setState(() {
      googleHealthConnected = info['connected'] == true;
      googleHealthEmail = info['email'];
      googleHealthPlatform = info['platform'];
    });

    if (googleHealthConnected) {
      _addLog('✅ Google Health API is CONNECTED');
      _addLog('   Email: ${googleHealthEmail ?? "unknown"}');
      _addLog('   Platform: ${googleHealthPlatform ?? "unknown"}');
    } else {
      _addLog('❌ Google Health API is NOT connected');
      _addLog('   → Tap "Connect Google Health" to start authentication');
    }
  }

  // ─── Connect to Google Health ──────────────────────────────────────────────
  Future<void> _connectGoogleHealth() async {
    _addLog('Starting Google Sign-In for Health scopes...');
    setState(() => isSyncing = true);

    try {
      final success = await HealthService.connect();

      if (success) {
        _addLog('✅ Google Health authentication SUCCESS');
        await _checkGoogleHealthStatus();

        // Automatically sync after successful connect
        await _syncNow();
      } else {
        _addLog('❌ Google Health authentication FAILED or cancelled by user');
        setState(() {
          lastSyncError = 'Google Sign-In failed or was cancelled';
        });
      }
    } catch (e, stack) {
      _addLog('❌ Exception during connect: $e');
      _addLog('Stack: $stack');
      setState(() => lastSyncError = e.toString());
    } finally {
      if (mounted) setState(() => isSyncing = false);
    }
  }

  // ─── Disconnect ────────────────────────────────────────────────────────────
  Future<void> _disconnectGoogleHealth() async {
    _addLog('Disconnecting Google Health...');
    await HealthService.disconnect();
    await _checkGoogleHealthStatus();
    _addLog('Disconnected');
  }

  // ─── Sync today data from Google Health → Backend ──────────────────────────
  Future<void> _syncNow() async {
    if (!HealthService.isConnected) {
      _addLog('❌ Cannot sync – Google Health is not connected');
      setState(() => lastSyncError = 'Google Health is not connected');
      return;
    }

    setState(() {
      isSyncing = true;
      lastSyncError = null;
    });

    _addLog('Fetching today\'s data from Google Health Cloud API...');

    try {
      final success = await HealthService.syncToBackend(widget.token);

      if (success) {
        _addLog('✅ Sync to backend SUCCESS');
        await loadRecords(); // refresh list
      } else {
        _addLog('❌ Sync to backend FAILED');
        setState(() => lastSyncError = 'Backend rejected the sync');
      }
    } catch (e) {
      _addLog('❌ Sync exception: $e');
      setState(() => lastSyncError = e.toString());
    } finally {
      if (mounted) setState(() => isSyncing = false);
    }
  }

  // ─── Load records from your backend ────────────────────────────────────────
  Future<void> loadRecords({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        isLoading = true;
        errorMessage = null;
        currentPage = 1;
      });
    }

    try {
      final response = await Dio().get(
        "${ApiConstants.baseUrl}/records",
        queryParameters: {
          "page": currentPage,
          "limit": limit,
        },
        options: Options(
          headers: {"Authorization": "Bearer ${widget.token}"},
        ),
      );

      if (!mounted) return;

      final data = response.data;
      final List<dynamic> list = data["data"] ?? [];

      setState(() {
        if (loadMore) {
          records.addAll(list.cast<Map<String, dynamic>>());
        } else {
          records = list.cast<Map<String, dynamic>>();
        }
        totalPages = data["pages"] ?? 1;
        isLoading = false;
      });

      _addLog('Loaded ${records.length} records from backend');
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?["message"] ?? "Failed to load records";
      setState(() {
        isLoading = false;
        errorMessage = msg;
      });
      _addLog('❌ Backend load error: $msg');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "Something went wrong";
      });
      _addLog('❌ Unexpected error: $e');
    }
  }

  Future<void> _loadMore() async {
    if (currentPage >= totalPages) return;
    currentPage++;
    await loadRecords(loadMore: true);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "-";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat("EEE, dd MMM yyyy").format(date);
    } catch (_) {
      return dateStr;
    }
  }

  // ─── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      appBar: AppBar(
        title: const Text(
          "Health Records",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _checkGoogleHealthStatus();
              loadRecords();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ═══════════════════════════════════════════════════════════════
          //  GOOGLE HEALTH STATUS + CONTROLS
          // ═══════════════════════════════════════════════════════════════
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: googleHealthConnected
                    ? Colors.green.shade300
                    : Colors.red.shade200,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      googleHealthConnected
                          ? Icons.check_circle
                          : Icons.error_outline,
                      color: googleHealthConnected ? Colors.green : Colors.red,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        googleHealthConnected
                            ? 'Google Health API Connected'
                            : 'Google Health API NOT Connected',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: googleHealthConnected
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (googleHealthConnected) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Email: ${googleHealthEmail ?? "-"}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Text(
                    'Platform: ${googleHealthPlatform ?? "-"}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
                if (lastSyncError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Last error: $lastSyncError',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!googleHealthConnected)
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: isSyncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.link),
                          label: Text(isSyncing ? 'Connecting...' : 'Connect Google Health'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff9f6eff),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isSyncing ? null : _connectGoogleHealth,
                        ),
                      )
                    else ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: isSyncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.sync),
                          label: Text(isSyncing ? 'Syncing...' : 'Sync Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isSyncing ? null : _syncNow,
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: isSyncing ? null : _disconnectGoogleHealth,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Disconnect'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════════════════
          //  DEBUG LOGS (expandable)
          // ═══════════════════════════════════════════════════════════════
          ExpansionTile(
            title: const Text(
              'Debug Logs (Google Health + Backend)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            initiallyExpanded: !googleHealthConnected,
            children: [
              Container(
                width: double.infinity,
                height: 160,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  itemCount: debugLogs.length,
                  itemBuilder: (context, index) {
                    final log = debugLogs[index];
                    final isError = log.contains('❌') || log.toLowerCase().contains('error');
                    return Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: isError ? Colors.redAccent : Colors.greenAccent,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // ═══════════════════════════════════════════════════════════════
          //  RECORDS LIST
          // ═══════════════════════════════════════════════════════════════
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xff9f6eff)),
                  )
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(errorMessage!,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => loadRecords(),
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      )
                    : records.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                "No health records yet.\n\nConnect Google Health and tap Sync Now to start collecting data.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => loadRecords(),
                            color: const Color(0xff9f6eff),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: records.length +
                                  (currentPage < totalPages ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == records.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: TextButton(
                                        onPressed: _loadMore,
                                        child: const Text("Load more"),
                                      ),
                                    ),
                                  );
                                }

                                final record = records[index];
                                return _RecordCard(
                                  record: record,
                                  formattedDate: _formatDate(record["date"]),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final String formattedDate;

  const _RecordCard({
    required this.record,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xff9f6eff).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    record["source"] ?? "Unknown",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff9f6eff),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metricChip(Icons.directions_walk, "Steps",
                    "${record["steps"] ?? 0}"),
                _metricChip(Icons.local_fire_department, "Calories",
                    "${record["calories"] ?? 0}"),
                _metricChip(Icons.bedtime, "Sleep",
                    "${record["sleepHours"] ?? 0} h"),
                _metricChip(
                    Icons.favorite, "HR", "${record["heartRate"] ?? 0}"),
                _metricChip(Icons.monitor_heart, "Resting HR",
                    "${record["restingHeartRate"] ?? 0}"),
                _metricChip(Icons.straighten, "Distance",
                    "${record["distanceWalked"] ?? 0} km"),
                _metricChip(Icons.bloodtype, "SpO₂",
                    "${record["bloodOxygen"] ?? 0}%"),
                _metricChip(Icons.thermostat, "Temp",
                    "${record["bodyTemperature"] ?? 0}°"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricChip(IconData icon, String label, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
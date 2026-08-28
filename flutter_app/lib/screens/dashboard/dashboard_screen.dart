import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'record_health_screen.dart';
import 'health_sync_screen.dart';
import 'ai_chat_screen.dart';
import '../commons/sidebar.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/auth_manager.dart';
import '../../core/services/health_service.dart';
import '../../core/services/health_background_sync.dart';
import '../onboarding&account/user_account_screen.dart';
import '../auth/welcome_screen.dart';
import '../../features/cv/cv_analysis_screen.dart';
import '../../features/ml/ml_health_dashboard_screen.dart';
import '../../features/ml/ml_health_history_screen.dart';
import '../../features/ml/ml_health_details_screen.dart';
import '../../core/services/ml_health_service.dart';

/// Unified application dashboard.
///
/// This file combines the functionality that previously existed in:
///   1. dashboard_screen.dart
///   2. health_dashboard_screen.dart
///
/// The separate HealthDashboardScreen is no longer required.
class DashboardScreen extends StatefulWidget {
  final String token;

  const DashboardScreen({
    super.key,
    required this.token,
  });

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen>
    with WidgetsBindingObserver {
  // ===========================================================================
  // DASHBOARD STATE
  // ===========================================================================

  bool isLoading = true;
  bool isHealthLoading = false;
  bool isConnectingHealth = false;
  bool isSyncing = false;

  Map<String, dynamic>? dashboard;

  List<Map<String, dynamic>> healthRecords = [];
  Map<String, dynamic>? _mlAnalysis;
  bool _mlLoading = false;
  bool _mlAnalyzing = false;
  String? _mlError;

  Map<String, dynamic>? latestHealthRecord;

  String? errorMessage;
  String? healthErrorMessage;

  String healthRecordStatus =
      'Connect Google Health to view your records';

  Timer? _healthRefreshTimer;

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initializeHealthAndDashboard();

    _healthRefreshTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _maybeAutomaticHealthSync(),
    );
  }

  Future<void> _loadMlHealthAnalysis() async {
    if (_mlLoading) return;

    if (mounted) {
      setState(() {
        _mlLoading = true;
        _mlError = null;
      });
    }

    try {
      final result = await MlHealthService.getLatestAnalysis(
        token: widget.token,
      );

      if (!mounted) return;

      final rawData = result['data'];

      if (result['success'] == true && rawData is Map) {
        setState(() {
          _mlAnalysis = Map<String, dynamic>.from(rawData);
          _mlLoading = false;
        });
      } else {
        setState(() {
          _mlAnalysis = null;
          _mlLoading = false;

          _mlError = result['message']?.toString() ??
              'No ML health analysis available yet.';
        });
      }
    } catch (e) {
      debugPrint('[Dashboard] ML health load error: $e');

      if (!mounted) return;

      setState(() {
        _mlLoading = false;
        _mlError = 'Unable to load ML health analysis.';
      });
    }
  }


  Map<String, dynamic> _currentMlProfile() {
    final rawProfile = dashboard?['profile'];
    return rawProfile is Map
        ? Map<String, dynamic>.from(rawProfile)
        : <String, dynamic>{};
  }

  String _recordDateKey(Map<String, dynamic>? record) {
    if (record == null) return '';
    return (record['date'] ??
            record['recordDate'] ??
            record['createdAt'] ??
            record['updatedAt'] ??
            '')
        .toString();
  }

  String _analysisSourceDateKey(Map<String, dynamic>? analysis) {
    if (analysis == null) return '';
    return (analysis['sourceRecordDate'] ??
            analysis['latestHealthRecord']?['date'] ??
            '')
        .toString();
  }

Future<void> _runMlAnalysis({
bool showFeedback = true,
}) async {
if (_mlAnalyzing) return;
if (!mounted) return;

setState(() {
_mlAnalyzing = true;
_mlError = null;
});

try {
// The backend is the source of truth.
//
// It retrieves the latest health records from the database,
// fills missing fields using available averages,
// performs the ML analysis,
// and saves the new analysis as the latest analysis.
final result = await MlHealthService.analyze(
token: widget.token,
profile: _currentMlProfile(),
);


if (!mounted) return;

if (result['success'] == true) {
  final rawData = result['data'];

  if (rawData is Map) {
    setState(() {
      _mlAnalysis = Map<String, dynamic>.from(rawData);
    });
  }

  // Reload from the backend database so the dashboard always
  // displays the persisted latest ML analysis.
  await _loadMlHealthAnalysis();

  if (!mounted) return;

  if (showFeedback) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'ML analysis completed and saved successfully.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
} else {
  final message =
      result['message']?.toString() ??
      'Unable to complete ML health analysis.';

  setState(() {
    _mlError = message;
  });

  if (showFeedback) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}


} catch (e) {
debugPrint('[Dashboard] ML analysis error: $e');


if (!mounted) return;

setState(() {
  _mlError =
      'Unable to complete ML health analysis.';
});

if (showFeedback) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'ML analysis failed: $e',
      ),
      backgroundColor: Colors.redAccent,
    ),
  );
}


} finally {
if (mounted) {
setState(() {
_mlAnalyzing = false;
});
}
}
}

Future<void> _ensureLatestMlAnalysis() async {
if (_mlAnalyzing) return;

try {
// Ask the backend for the actual latest saved health record.
// Do not depend on the local Flutter healthRecords list.
final result =
await MlHealthService.getLatestHealthRecord(
token: widget.token,
);


if (!mounted) return;

if (result['success'] != true) {
  return;
}

final rawData = result['data'];

if (rawData is! Map) {
  return;
}

final data =
    Map<String, dynamic>.from(rawData);

final rawLatestRecord =
    data['latestRecord'];

if (rawLatestRecord is! Map) {
  return;
}

final backendLatestRecord =
    Map<String, dynamic>.from(rawLatestRecord);

final latestRecordDate =
    _recordDateKey(backendLatestRecord);

final analyzedRecordDate =
    _analysisSourceDateKey(_mlAnalysis);

// Run ML analysis automatically when:
//
// 1. No saved ML analysis exists, OR
// 2. The latest health record is newer/different from
//    the health record used for the previous analysis.
if (_mlAnalysis == null ||
    analyzedRecordDate.isEmpty ||
    latestRecordDate != analyzedRecordDate) {
  await _runMlAnalysis(
    showFeedback: false,
  );
}


} catch (e) {
debugPrint(
'[Dashboard] Latest ML analysis check error: $e',
);
}
}

  Future<void> _initializeHealthAndDashboard() async {
    await HealthService.initialize();

    await Future.wait([
      loadDashboard(),
      _loadMlHealthAnalysis(),
    ]);

    await _maybeAutomaticHealthSync();

    if (HealthService.isConnected) {
      await HealthBackgroundSync.ensureScheduled();

      await loadHealthOverview();

      // Reload ML analysis after health data is available.
      await _loadMlHealthAnalysis();
    }
  }

  Future<void> _maybeAutomaticHealthSync() async {
    if (!mounted || isLoading || isHealthLoading || !HealthService.isConnected) {
      return;
    }

    try {
      final token = await AuthManager().getToken();
      if (token == null || token.isEmpty) return;

      final due = await HealthService.isHealthSyncDue(token);
      if (due) {
        await _openHealthSyncScreen(force: false);
      }
    } catch (e) {
      debugPrint('[Dashboard] Sync-point check failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When the user returns to the app, immediately perform the due check
      // instead of waiting for the hourly timer.
      _maybeAutomaticHealthSync();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _healthRefreshTimer?.cancel();

    super.dispose();
  }

  // ===========================================================================
  // LOAD MAIN DASHBOARD
  // ===========================================================================

  Future<void> loadDashboard() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await Dio().get(
        "${ApiConstants.baseUrl}/dashboard",

        options: Options(
          headers: {
            "Authorization":
                "Bearer ${widget.token}",
          },
        ),
      );

      if (!mounted) return;

      // Dio decodes JSON objects as Map<dynamic, dynamic>.
      // Convert the dashboard payload explicitly so all widgets receive
      // Map<String, dynamic> and avoid runtime cast errors.
      final responseData = response.data;
      final rawDashboard = responseData is Map
          ? responseData["data"]
          : null;

      final Map<String, dynamic> dashboardData =
          rawDashboard is Map
              ? Map<String, dynamic>.from(rawDashboard)
              : <String, dynamic>{};

      setState(() {
        dashboard = dashboardData;
        isLoading = false;
      });

      // If Google Health is already connected,
      // load its records.
      if (HealthService.isConnected) {
        await loadHealthOverview();
      }
    } on DioException catch (e) {
      if (!mounted) return;

      if (e.response?.statusCode == 401) {
        debugPrint(
          "Token expired or invalid (401). Logging out...",
        );

        await _forceLogout();

        return;
      }

      setState(() {
        isLoading = false;
        errorMessage =
            "Failed to load dashboard";
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to load dashboard',
          ),
          backgroundColor:
              Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            "Something went wrong";
      });

      debugPrint(
        'Dashboard load error: $e',
      );
    }
  }

  // ===========================================================================
  // GOOGLE HEALTH - LOAD ALL RECORDS
  // ===========================================================================

  Future<void> loadHealthOverview() async {
    if (!mounted) return;

    setState(() {
      isHealthLoading = true;
      healthErrorMessage = null;
      healthRecordStatus = 'Loading saved health data...';
    });

    try {
      final token = await AuthManager().getToken();

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found.');
      }

      final history =
          await HealthService.loadStoredHealthHistory(token);

      final rawRecords = history['records'];

      final records = rawRecords is List
          ? rawRecords
              .whereType<Map>()
              .map(
                (record) =>
                    Map<String, dynamic>.from(record),
              )
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        healthRecords = records;

        latestHealthRecord =
            records.isNotEmpty
                ? records.first
                : null;

        isHealthLoading = false;

        healthRecordStatus =
            records.isEmpty
                ? 'No local health records found'
                : 'Latest saved health record';
      });

      // -----------------------------------------------------------------------
      // IMPORTANT:
      //
      // Do NOT depend on the local Flutter healthRecords list for ML.
      //
      // The backend database is the source of truth for:
      // - latest health record
      // - latest ML analysis
      // - automatic ML analysis
      // -----------------------------------------------------------------------

      await _loadMlHealthAnalysis();

      await _ensureLatestMlAnalysis();
    } catch (e) {
      debugPrint(
        'Stored health overview error: $e',
      );

      if (!mounted) return;

      setState(() {
        isHealthLoading = false;

        healthErrorMessage =
            'Unable to load saved health data';

        healthRecordStatus =
            'Unable to load saved health data';
      });

      // Even if local health loading fails, try loading the
      // backend ML result because the ML backend may still have data.
      try {
        await _loadMlHealthAnalysis();
        await _ensureLatestMlAnalysis();
      } catch (mlError) {
        debugPrint(
          '[Dashboard] ML fallback check failed: $mlError',
        );
      }
    }
  }

  Future<void> _openHealthSyncScreen({required bool force}) async {
    if (!mounted || isSyncing) return;
    final token = await AuthManager().getToken();
    if (token == null || token.isEmpty) return;

    setState(() => isSyncing = true);
    final syncResult = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => HealthSyncScreen(
          force: force,
          onSync: () => HealthService.smartSyncHealth(token, force: force),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => isSyncing = false);

    // Only enable the recurring worker after the sync screen reports a
    // successful sync result. A cancelled/failed sync does not activate it.
    if (syncResult != null) {
      await HealthBackgroundSync.ensureScheduled();
    }

    await loadHealthOverview();

    await _loadMlHealthAnalysis();
  }

  // ===========================================================================
  // GOOGLE HEALTH - CONNECT
  // ===========================================================================

  Future<void> connectGoogleHealth() async {
    if (isConnectingHealth) return;

    if (!mounted) return;

    setState(() {
      isConnectingHealth = true;

      healthRecordStatus =
          'Connecting to Google Health...';
    });

    try {
      final connected =
          await HealthService.connect();

      if (!mounted) return;

      if (!connected) {
        setState(() {
          isConnectingHealth = false;

          healthRecordStatus =
              'Google Health connection cancelled';
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Google Health connection was cancelled.",
            ),
            backgroundColor:
                Colors.orange,
          ),
        );

        return;
      }

      if (!mounted) return;
      setState(() {
        isConnectingHealth = false;
      });
      await _openHealthSyncScreen(force: true);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Google Health connected successfully.",
          ),
          backgroundColor:
              Colors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isConnectingHealth = false;

        healthRecordStatus =
            'Unable to load Google Health data';
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Google Health connection failed: $e",
          ),
          backgroundColor:
              Colors.redAccent,
        ),
      );
    }
  }

  // ===========================================================================
  // AUTOMATIC HEALTH RECORD SAVE
  // ===========================================================================

  Future<void>
      _autoSyncLatestHealthRecord(
    Map<String, dynamic> record,
  ) async {
    try {
      final token =
          await AuthManager().getToken();

      if (token == null ||
          token.isEmpty) {
        return;
      }

      final saved =
          await HealthService
              .syncLatestRecordToBackend(
        token,
        record,
      );

      debugPrint(
        '[Dashboard] Automatic health record save: '
        '${saved ? 'success' : 'failed'}',
      );
    } catch (e) {
      debugPrint(
        '[Dashboard] Automatic health record save error: $e',
      );
    }
  }

  // ===========================================================================
  // SYNC HEALTH DATA TO BACKEND
  // ===========================================================================

  Future<void> syncHealthToBackend() async {
    if (!HealthService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connect Google Health first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await _openHealthSyncScreen(force: true);
  }

  // ===========================================================================
  // LOGOUT
  // ===========================================================================

  Future<void> _handleLogout() async {
    await AuthManager().clearToken();

    if (!mounted) return;

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const WelcomeScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _forceLogout() async {
    await AuthManager().clearToken();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          "Session expired. Please login again.",
        ),
        backgroundColor:
            Colors.orange,
      ),
    );

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const WelcomeScreen(),
      ),
      (route) => false,
    );
  }

  // ===========================================================================
  // OPEN ALL HEALTH RECORDS
  // ===========================================================================

  void _openAllRecords() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const RecordHealthScreen(),
      ),
    ).then((_) {
      loadHealthOverview();
    });
  }

  // ===========================================================================
  // OPEN USER ACCOUNT / PROFILE
  // ===========================================================================

  Future<void> _openUserAccount(
    Map<String, dynamic> user,
    Map<String, dynamic> profile,
  ) async {
    if (!mounted) return;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UserAccountScreen(
          user: user,
          profile: profile,
        ),
      ),
    );

    if (!mounted) return;

    // UserAccountScreen returns true after a successful profile update.
    // Reload the dashboard so the updated profile information is shown
    // immediately without requiring the user to restart the app.
    if (updated == true) {
      await loadDashboard();
    }
  }

  // ===========================================================================
  // ML HEALTH NAVIGATION
  // ===========================================================================

  Future<void> _openMlHealthDashboard() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MlHealthDashboardScreen(
          token: widget.token,
        ),
      ),
    );

    if (!mounted) return;

    await _loadMlHealthAnalysis();
  }

  Future<void> _openMlHealthDetails() async {
    // The details screen requires a concrete analysis payload. Refresh it
    // first so sidebar navigation always uses the latest available analysis.
    if (_mlAnalysis == null) {
      await _loadMlHealthAnalysis();
    }

    if (!mounted) return;

    if (_mlAnalysis == null) {
      // No analysis is available yet. Open the ML dashboard so its existing
      // loading, empty-state and retry functionality remains available.
      await _openMlHealthDashboard();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MlHealthDetailsScreen(
          analysis: _mlAnalysis!,
        ),
      ),
    );

    if (!mounted) return;

    await _loadMlHealthAnalysis();
  }

  Future<void> _openMlHealthHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MlHealthHistoryScreen(
          token: widget.token,
        ),
      ),
    );

    if (!mounted) return;

    await _loadMlHealthAnalysis();
  }

  // ===========================================================================
  // NUMBER HELPERS
  // ===========================================================================

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  int _toInt(dynamic value) {
    return _toDouble(value).round();
  }

  // ===========================================================================
  // AVERAGE
  // ===========================================================================

  double _average(String key) {
    if (healthRecords.isEmpty) {
      return 0;
    }

    double total = 0;
    int count = 0;

    for (final record
        in healthRecords) {
      final value =
          _toDouble(record[key]);

      // Missing values must not be treated as zero.
      if (value > 0) {
        total += value;
        count++;
      }
    }

    if (count == 0) {
      return 0;
    }

    return total / count;
  }

  // ===========================================================================
  // DATE HELPERS
  // ===========================================================================

  String _localDateKey(
    DateTime date,
  ) {
    final year =
        date.year.toString().padLeft(
              4,
              '0',
            );

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    return '$year-$month-$day';
  }

  String _formatHealthDate(
    dynamic value,
  ) {
    if (value == null) {
      return "Date unavailable";
    }

    try {
      final date =
          DateTime.parse(
        value.toString(),
      ).toLocal();

      final today =
          DateTime.now();

      if (date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) {
        return "Today • "
            "${date.day.toString().padLeft(2, '0')}/"
            "${date.month.toString().padLeft(2, '0')}/"
            "${date.year}";
      }

      const months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];

      return
          "${months[date.month - 1]} "
          "${date.day}, "
          "${date.year}";
    } catch (_) {
      return value.toString();
    }
  }

  String _formatRecordedDate(
    String? date,
  ) {
    if (date == null ||
        date.isEmpty) {
      return 'Date unavailable';
    }

    final parsed =
        DateTime.tryParse(date);

    if (parsed == null) {
      return date;
    }

    final local =
        parsed.toLocal();

    final day =
        local.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        local.month.toString().padLeft(
              2,
              '0',
            );

    final year =
        local.year.toString();

    return '$day/$month/$year';
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(
            color:
                Color(0xff9f6eff),
          ),
        ),
      );
    }

    // Normalize every nested JSON object before passing it to widgets.
    // Without this conversion, a fallback `{}` becomes Map<dynamic, dynamic>
    // and causes the runtime error:
    // _Map<dynamic, dynamic> is not a subtype of Map<String, dynamic>.
    final rawUser = dashboard?["user"];
    final rawProfile = dashboard?["profile"];
    final rawDevices = dashboard?["devices"];

    final Map<String, dynamic> user =
        rawUser is Map
            ? Map<String, dynamic>.from(rawUser)
            : <String, dynamic>{};

    final Map<String, dynamic> profile =
        rawProfile is Map
            ? Map<String, dynamic>.from(rawProfile)
            : <String, dynamic>{};

    final Map<String, dynamic> devices =
        rawDevices is Map
            ? Map<String, dynamic>.from(rawDevices)
            : <String, dynamic>{};

    final healthConnected =
        HealthService.isConnected ||
            devices["healthConnected"] ==
                true;

    return Scaffold(
      backgroundColor:
          const Color(0xfff4f7f6),

      drawer: HealthSidebar(
  user: user,
  profile: profile,
  healthConnected: healthConnected,
  token: widget.token,

  onDashboard: () {},

  onAccount: () {
    _openUserAccount(
      user,
      profile,
    );
  },

  onAllHealthHistory: _openAllRecords,

  onSyncHealth: _refreshAll,

  onMlHealthDashboard: _openMlHealthDashboard,

  onMlHealthDetails: _openMlHealthDetails,

  onMlHealthHistory: _openMlHealthHistory,

  onLogout: _handleLogout,
),
      // =======================================================================
      // BOTH FLOATING BUTTONS
      // =======================================================================

      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat,

      floatingActionButton:
          Column(
        mainAxisSize:
            MainAxisSize.min,

        crossAxisAlignment:
            CrossAxisAlignment.end,

        children: [
          // ---------------------------------------------------------------
          // COMPUTER VISION BUTTON
          // ---------------------------------------------------------------

          buildCVFloatingButton(),

          const SizedBox(
            height: 12,
          ),

          // ---------------------------------------------------------------
          // PULSE AI CHAT BUTTON
          // ---------------------------------------------------------------

          buildAIChatFloatingButton(),
        ],
      ),

      // =====================================================================
      // APP BAR
      // =====================================================================

      appBar: AppBar(
        title: const Text(
          "Pulse AI",
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        backgroundColor:
            Colors.white,

        elevation: 0,

        actions: [
          IconButton(
            tooltip:
                "All Health Records",

            icon: const Icon(
              Icons.history_rounded,
              color:
                  Color(0xff9f6eff),
            ),

            onPressed:
                _openAllRecords,
          ),

          IconButton(
            tooltip:
                "Refresh",

            icon: const Icon(
              Icons
                  .cloud_download_rounded,
              color:
                  Color(0xff9f6eff),
            ),

            onPressed:
                isHealthLoading
                    ? null
                    : _refreshAll,
          ),

          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color:
                  Colors.redAccent,
            ),

            tooltip:
                "Logout",

            onPressed:
                _handleLogout,
          ),
        ],
      ),

      // =====================================================================
      // BODY
      // =====================================================================

      body: RefreshIndicator(
        onRefresh: _refreshAll,

        color:
            const Color(0xff9f6eff),

        child:
            SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ===============================================================
              // USER PROFILE
              // ===============================================================

              _buildProfileHeader(
                user,
              ),

              const SizedBox(
                height: 24,
              ),

              // ===============================================================
              // PROFILE INFORMATION
              // ===============================================================

              _buildProfileCard(
                profile,
              ),

              const SizedBox(
                height: 28,
              ),

              // ===============================================================
              // PULSE AI ML HEALTH
              // ===============================================================

              _buildMlHealthSection(),

              const SizedBox(
                height: 28,
              ),

              // ===============================================================
              // GOOGLE HEALTH
              // ===============================================================

              _buildHealthSectionHeader(),

              const SizedBox(
                height: 12,
              ),

              if (!healthConnected)
                _buildConnectHealthCard()
              else if (isHealthLoading)
                _buildHealthLoadingCard()
              else if (latestHealthRecord !=
                  null) ...[
                _buildHealthHeader(),

                const SizedBox(
                  height: 16,
                ),

                _buildRecordDateCard(),

                const SizedBox(
                  height: 16,
                ),

                _buildLatestHealthCard(),

                const SizedBox(
                  height: 26,
                ),

                _buildAverageSection(),
              ]
              else
                _buildNoHealthDataCard(),

              const SizedBox(
                height: 24,
              ),

              // ===============================================================
              // HEALTH HISTORY
              // ===============================================================

              _buildHealthHistoryButton(),

              const SizedBox(
                height: 14,
              ),

              // ===============================================================
              // PUSH TO BACKEND
              // ===============================================================

              if (healthConnected &&
                  latestHealthRecord !=
                      null)
                _buildSyncButton(),

              // Extra bottom padding so the floating buttons
              // don't cover the last content.
              const SizedBox(
                height: 90,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // REFRESH ALL
  // ===========================================================================

  Future<void> _refreshAll() async {
    await loadDashboard();

    if (HealthService.isConnected) {
      await _openHealthSyncScreen(
        force: true,
      );
    }

    await loadHealthOverview();

    await _loadMlHealthAnalysis();
    await _ensureLatestMlAnalysis();
  }

  // ===========================================================================
  // PROFILE HEADER
  // ===========================================================================

  Widget _buildProfileHeader(
    Map<String, dynamic> user,
  ) {
    final photo =
        user["photoUrl"];

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,

            backgroundColor:
                Colors.grey.shade200,

            backgroundImage:
                photo != null &&
                        photo
                            .toString()
                            .isNotEmpty
                    ? NetworkImage(
                        photo.toString(),
                      )
                    : null,

            child: photo == null ||
                    photo
                        .toString()
                        .isEmpty
                ? const Icon(
                    Icons.person,
                    size: 50,
                    color:
                        Colors.grey,
                  )
                : null,
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            user["name"] ??
                "Unknown User",

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            user["email"] ?? "",

            textAlign:
                TextAlign.center,

            style: TextStyle(
              color:
                  Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PROFILE CARD
  // ===========================================================================

  Widget _buildProfileCard(
    Map<String, dynamic> profile,
  ) {
    return Container(
      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child: Column(
        children: [
          _buildInfoTile(
            "Nickname",
            profile["nickname"]
                    ?.toString() ??
                "-",
          ),

          _buildInfoTile(
            "Age",
            profile["age"]
                    ?.toString() ??
                "-",
          ),

          _buildInfoTile(
            "BMI",
            profile["bmi"]
                    ?.toString() ??
                "-",
          ),

          _buildInfoTile(
            "Health Goal",
            profile["healthGoal"]
                    ?.toString() ??
                "-",
          ),

          _buildInfoTile(
            "Activity Level",
            profile[
                        "activityLevel"]
                    ?.toString() ??
                "-",
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ML HEALTH SECTION
  // ===========================================================================

  Widget _buildMlHealthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xff6c5ce7).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Color(0xff6c5ce7),
                size: 24,
              ),
            ),

            const SizedBox(width: 12),

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pulse AI Health Intelligence',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  SizedBox(height: 3),

                  Text(
                    'Personalized wellness analysis and trends',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              tooltip: 'Refresh ML analysis',
              onPressed: (_mlLoading || _mlAnalyzing)
                  ? null
                  : () => _runMlAnalysis(),
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xff6c5ce7),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (_mlLoading)
          _buildMlLoadingCard()
        else if (_mlAnalysis != null)
          _buildMlAnalysisCard()
        else
          _buildMlEmptyCard(),
      ],
    );
  }

  Widget _buildMlLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(
            color: Color(0xff6c5ce7),
          ),

          SizedBox(height: 14),

          Text(
            'Analyzing your health data...',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMlAnalysisCard() {
    final analysis = _mlAnalysis ?? {};

    final rawScores = analysis['scores'];

    final scores = rawScores is Map
        ? Map<String, dynamic>.from(rawScores)
        : <String, dynamic>{};

    final rawWellness = analysis['wellness'];

    final wellness = rawWellness is Map
        ? Map<String, dynamic>.from(rawWellness)
        : <String, dynamic>{};

    final rawQuality = analysis['dataQuality'];

    final dataQuality = rawQuality is Map
        ? Map<String, dynamic>.from(rawQuality)
        : <String, dynamic>{};

    final overallScore = _toDouble(
      scores['overallWellbeingScore'],
    );

    final heartScore = _toDouble(
      scores['heartHealthScore'],
    );

    final healthScore = _toDouble(
      scores['healthScore'],
    );

    final personalScore = _toDouble(
      scores['personalWellnessScore'],
    );

    final status = wellness['status']
            ?.toString()
            .replaceAll('_', ' ') ??
        'unknown';

    final recordsAnalyzed = _toInt(
      analysis['recordsAnalyzed'] ??
          dataQuality['recordsAnalyzed'],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff6c5ce7),
            Color(0xff9f6eff),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff6c5ce7)
                .withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Health Score',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'AI Wellbeing Analysis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Center(
            child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.45),
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      overallScore.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const Text(
                      'OVERALL SCORE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _buildMlScoreItem(
                  'Heart',
                  heartScore,
                  Icons.favorite_rounded,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildMlScoreItem(
                  'Health',
                  healthScore,
                  Icons.health_and_safety_rounded,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildMlScoreItem(
                  'Wellness',
                  personalScore,
                  Icons.spa_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white70,
                  size: 18,
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    '$recordsAnalyzed health records analyzed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 14,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_mlLoading || _mlAnalyzing)
                  ? null
                  : () => _runMlAnalysis(),
              icon: _mlAnalyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_graph_rounded),
              label: Text(
                _mlAnalyzing
                    ? 'Analyzing Latest Records...'
                    : 'Run ML Analysis',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff6c5ce7),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openMlHealthDashboard,
                  icon: const Icon(
                    Icons.insights_rounded,
                  ),
                  label: const Text(
                    'Details',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Colors.white54,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openMlHealthHistory,
                  icon: const Icon(
                    Icons.show_chart_rounded,
                  ),
                  label: const Text(
                    'History',
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor:
                        const Color(0xff6c5ce7),
                    backgroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMlScoreItem(
    String label,
    double score,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 18,
          ),

          const SizedBox(height: 7),

          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMlEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xff6c5ce7)
              .withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.psychology_outlined,
            size: 48,
            color: Color(0xff6c5ce7),
          ),

          const SizedBox(height: 12),

          const Text(
            'ML Health Analysis Not Available',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _mlError ??
                'Sync health data to generate your personalized wellness analysis.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_mlLoading || _mlAnalyzing)
                  ? null
                  : () => _runMlAnalysis(),
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Try Again',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xff6c5ce7),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HEALTH SECTION HEADER
  // ===========================================================================

  Widget _buildHealthSectionHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,

          decoration:
              BoxDecoration(
            color:
                Colors.red.withOpacity(
              0.10,
            ),

            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),

          child: const Icon(
            Icons.favorite_rounded,
            color:
                Colors.redAccent,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                "Health Overview",

                style:
                    TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              SizedBox(
                height: 2,
              ),

              Text(
                "Your latest Google Health records",

                style:
                    TextStyle(
                  fontSize: 12,
                  color:
                      Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // CONNECT HEALTH CARD
  // ===========================================================================

  Widget _buildConnectHealthCard() {
    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xff9f6eff,
                  ).withOpacity(
                    0.10,
                  ),

                  shape:
                      BoxShape.circle,
                ),

                child:
                    const Icon(
                  Icons
                      .health_and_safety_rounded,
                  color:
                      Color(0xff9f6eff),
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      "Connect Google Health",

                      style:
                          TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    SizedBox(
                      height: 3,
                    ),

                    Text(
                      "View your latest health records and averages",

                      style:
                          TextStyle(
                        fontSize: 11,
                        color:
                            Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          SizedBox(
            width:
                double.infinity,

            child:
                ElevatedButton.icon(
              onPressed:
                  isConnectingHealth
                      ? null
                      : connectGoogleHealth,

              icon:
                  isConnectingHealth
                      ? const SizedBox(
                          width: 16,
                          height: 16,

                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.link_rounded,
                        ),

              label: Text(
                isConnectingHealth
                    ? "Connecting..."
                    : "Connect Google Health",
              ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xff9f6eff,
                ),

                foregroundColor:
                    Colors.white,

                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 14,
                ),

                elevation: 0,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HEALTH LOADING CARD
  // ===========================================================================

  Widget _buildHealthLoadingCard() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(30),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child:
          const Column(
        children: [
          CircularProgressIndicator(
            color:
                Color(0xff9f6eff),
          ),

          SizedBox(
            height: 14,
          ),

          Text(
            "Loading your health records...",

            style:
                TextStyle(
              color:
                  Colors.black54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DETAILED HEALTH HEADER
  // ===========================================================================

  Widget _buildHealthHeader() {
    final latest =
        latestHealthRecord ?? {};

    final email =
        latest['email']
            ?.toString();

    final source =
        latest['source']
                ?.toString() ??
            'Google Health Cloud API';

    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xff12c2e9),
            Color(0xffc471ed),
            Color(0xfff64f59),
          ],
        ),

        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.all(
                  10,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.white
                      .withOpacity(
                    0.18,
                  ),

                  shape:
                      BoxShape.circle,
                ),

                child: const Icon(
                  Icons
                      .health_and_safety_rounded,
                  color:
                      Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              const Expanded(
                child: Text(
                  'Google Health Connected',

                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.all(
                  6,
                ),

                decoration:
                    const BoxDecoration(
                  color:
                      Colors.white,

                  shape:
                      BoxShape.circle,
                ),

                child:
                    const Icon(
                  Icons.check_rounded,
                  color:
                      Colors.teal,
                  size: 18,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          Text(
            healthRecordStatus,

            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize: 14,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            source,

            style:
                const TextStyle(
              color:
                  Colors.white70,
              fontSize: 11,
            ),
          ),

          if (email != null &&
              email.isNotEmpty) ...[
            const SizedBox(
              height: 8,
            ),

            Row(
              children: [
                const Icon(
                  Icons
                      .account_circle_outlined,
                  color:
                      Colors.white70,
                  size: 14,
                ),

                const SizedBox(
                  width: 5,
                ),

                Expanded(
                  child: Text(
                    email,

                    style:
                        const TextStyle(
                      color:
                          Colors.white70,
                      fontSize: 11,
                    ),

                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // RECORD DATE CARD
  // ===========================================================================

  Widget _buildRecordDateCard() {
    final date =
        latestHealthRecord?['date']
            ?.toString();

    final isToday =
        date ==
            _localDateKey(
              DateTime.now(),
            );

    return Container(
      padding:
          const EdgeInsets.all(17),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border:
            Border.all(
          color: Colors.black
              .withOpacity(
            0.04,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(
              0.025,
            ),
            blurRadius: 10,
            offset:
                const Offset(
              0,
              4,
            ),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.all(
              10,
            ),

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xff9f6eff,
              ).withOpacity(
                0.10,
              ),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child:
                const Icon(
              Icons
                  .calendar_month_rounded,
              color:
                  Color(0xff9f6eff),
              size: 22,
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  isToday
                      ? "Today's Health Record"
                      : 'Latest Recorded Health Data',

                  style:
                      const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xff263238),
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  date != null
                      ? _formatRecordedDate(
                          date,
                        )
                      : 'No recorded date',

                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xff9f6eff),
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),

            decoration:
                BoxDecoration(
              color: isToday
                  ? Colors.teal
                      .withOpacity(
                      0.10,
                    )
                  : Colors.orange
                      .withOpacity(
                      0.10,
                    ),

              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),

            child: Text(
              isToday
                  ? 'TODAY'
                  : 'LATEST',

              style:
                  TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight.w800,
                color: isToday
                    ? Colors.teal
                    : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LATEST HEALTH RECORD
  // ===========================================================================

  Widget _buildLatestHealthCard() {
    final record =
        latestHealthRecord!;

    final date =
        record["date"];

    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,

          colors: [
            Color(0xff6c5ce7),
            Color(0xff9f6eff),
          ],
        ),

        borderRadius:
            BorderRadius.circular(
          24,
        ),

        boxShadow: [
          BoxShadow(
            color:
                const Color(
              0xff9f6eff,
            ).withOpacity(
              0.20,
            ),

            blurRadius: 18,

            offset:
                const Offset(
              0,
              8,
            ),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Latest Health Record",

                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.white
                      .withOpacity(
                    0.18,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    8,
                  ),
                ),

                child:
                    const Text(
                  "LATEST",

                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 6,
          ),

          Row(
            children: [
              const Icon(
                Icons
                    .calendar_today_rounded,
                color:
                    Colors.white70,
                size: 13,
              ),

              const SizedBox(
                width: 6,
              ),

              Text(
                "Recorded ${_formatHealthDate(date)}",

                style:
                    const TextStyle(
                  color:
                      Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          GridView.count(
            crossAxisCount: 2,

            crossAxisSpacing: 10,

            mainAxisSpacing: 10,

            childAspectRatio:
                1.55,

            shrinkWrap: true,

            physics:
                const NeverScrollableScrollPhysics(),

            children: [
              _buildHealthMetric(
                icon: Icons
                    .directions_walk_rounded,

                title: "Steps",

                value:
                    "${_toInt(record["steps"])}",

                unit:
                    "steps",
              ),
              _buildHealthMetric(
                icon: Icons
                    .favorite_rounded,
                title:
                    "Heart Rate",
                value:
                    _toInt(record["heartRate"]) > 0
                        ? "${_toInt(record["heartRate"])}"
                        : "—",
                unit:
                    "BPM",
              ),

              _buildHealthMetric(
                icon: Icons
                    .favorite_border_rounded,
                title:
                    "Resting Heart",
                value:
                    _toInt(record["restingHeartRate"]) > 0
                        ? "${_toInt(record["restingHeartRate"])}"
                        : "—",
                unit:
                    "BPM",
              ),

              _buildHealthMetric(
                icon: Icons
                    .stairs_rounded,

                title:
                    "Stairs",

                value:
                    "${_toInt(record["floors"])}",

                unit:
                    "stairs",
              ),

              _buildHealthMetric(
                icon: Icons.air_rounded,

                title:
                    "SpO₂",

                value:
                    _toDouble(
                  record[
                      "bloodOxygen"],
                ).toStringAsFixed(
                  1,
                ),

                unit:
                    "%",
              ),

              _buildHealthMetric(
                icon: Icons
                    .local_fire_department_rounded,

                title:
                    "Active Zone",

                value:
                    "${_toInt(record["activeZoneMinutes"])}",

                unit:
                    "min",
              ),

              _buildHealthMetric(
                icon: Icons
                    .monitor_weight_rounded,

                title:
                    "Weight",

                value:
                    _toDouble(
                  record["weight"],
                ).toStringAsFixed(
                  1,
                ),

                unit:
                    "kg",
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HEALTH METRIC
  // ===========================================================================

  Widget _buildHealthMetric({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(12),

      decoration:
          BoxDecoration(
        color: Colors.white
            .withOpacity(
          0.13,
        ),

        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            color:
                Colors.white,
            size: 22,
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [
                Text(
                  title,

                  style:
                      const TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 9,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,

                  children: [
                    Flexible(
                      child: Text(
                        value,

                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 3,
                    ),

                    Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 2,
                      ),

                      child:
                          Text(
                        unit,

                        style:
                            const TextStyle(
                          color:
                              Colors.white70,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // AVERAGES
  // ===========================================================================

  Widget _buildAverageSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    "Your Averages",

                    style:
                        TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  SizedBox(
                    height: 3,
                  ),

                  Text(
                    "Based on all recorded health days",

                    style:
                        TextStyle(
                      fontSize: 11,
                      color:
                          Colors.black45,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xff9f6eff,
                ).withOpacity(
                  0.10,
                ),

                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),

              child:
                  Text(
                "${healthRecords.length} DAYS",

                style:
                    const TextStyle(
                  color:
                      Color(0xff9f6eff),
                  fontSize: 9,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 14,
        ),

        _buildAverageMetric(
          icon: Icons
              .directions_walk_rounded,

          title:
              "Average Steps",

          value:
              _average("steps")
                  .round()
                  .toString(),

          unit:
              "steps / day",

          color:
              Colors.orange,
        ),

        _buildAverageMetric(
          icon:
              Icons.favorite_rounded,

          title:
              "Average Heart Rate",

          value:
              _average("heartRate")
                  .toStringAsFixed(
                1,
              ),

          unit:
              "BPM",

          color:
              Colors.redAccent,
        ),
        _buildAverageMetric(
          icon: Icons.favorite_border_rounded,
          title:
              "Average Resting Heart Rate",
          value:
              _average("restingHeartRate")
                  .toStringAsFixed(1),
          unit:
              "BPM",
          color:
              Colors.pinkAccent,
        ),

        _buildAverageMetric(
          icon:
              Icons.stairs_rounded,
          title:
              "Average Stairs",

          value:
              _average("floors")
                  .toStringAsFixed(
                1,
              ),

          unit:
              "stairs / day",

          color:
              Colors.deepPurple,
        ),

        _buildAverageMetric(
          icon:
              Icons.air_rounded,

          title:
              "Average SpO₂",

          value:
              _average("bloodOxygen")
                  .toStringAsFixed(
                1,
              ),

          unit:
              "%",

          color:
              Colors.teal,
        ),

        _buildAverageMetric(
          icon: Icons
              .local_fire_department_rounded,

          title:
              "Average Active Zone",

          value:
              _average(
                "activeZoneMinutes",
              ).toStringAsFixed(
                1,
              ),

          unit:
              "min / day",

          color:
              Colors.deepOrange,
        ),

        _buildAverageMetric(
          icon: Icons
              .monitor_weight_rounded,

          title:
              "Average Weight",

          value:
              _average("weight")
                  .toStringAsFixed(
                1,
              ),

          unit:
              "kg",

          color:
              Colors.blueGrey,
        ),
      ],
    );
  }

  Widget _buildAverageMetric({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      padding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          17,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration:
                BoxDecoration(
              color: color
                  .withOpacity(
                0.10,
              ),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Text(
              title,

              style:
                  const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w700,
                color:
                    Color(0xff374151),
              ),
            ),
          ),

          Text(
            value,

            style:
                const TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xff263238),
            ),
          ),

          const SizedBox(
            width: 5,
          ),

          SizedBox(
            width: 65,

            child: Text(
              unit,

              style:
                  const TextStyle(
                fontSize: 9,
                color:
                    Colors.black38,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // NO HEALTH DATA
  // ===========================================================================

  Widget _buildNoHealthDataCard() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(25),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Column(
        children: [
          const Icon(
            Icons
                .health_and_safety_outlined,

            size: 48,

            color:
                Color(0xff9f6eff),
          ),

          const SizedBox(
            height: 12,
          ),

          const Text(
            "No health records found",

            style:
                TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            healthErrorMessage ??
                "Your Google Health account is connected, "
                    "but no recorded health data was found.",

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              fontSize: 11,
              color:
                  Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HEALTH HISTORY BUTTON
  // ===========================================================================

  Widget _buildHealthHistoryButton() {
    return SizedBox(
      width:
          double.infinity,

      child:
          OutlinedButton.icon(
        onPressed:
            _openAllRecords,

        icon: const Icon(
          Icons.history_rounded,
        ),

        label: const Text(
          "View All Health Records",
        ),

        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              const Color(
            0xff9f6eff,
          ),

          side:
              const BorderSide(
            color:
                Color(0xff9f6eff),
          ),

          padding:
              const EdgeInsets.symmetric(
            vertical: 15,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              15,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // FLOATING COMPUTER VISION BUTTON
  // ===========================================================================

  Widget buildCVFloatingButton() {
    return FloatingActionButton(
      heroTag:
          'cv_analysis_fab',

      tooltip:
          'Computer Vision',

      onPressed: () async {
        await Navigator.push(
          context,

          MaterialPageRoute(
            builder: (_) =>
                const CVAnalysisScreen(),
          ),
        );
      },

      child: const Icon(
        Icons
            .face_retouching_natural,

        size: 24,
      ),

      backgroundColor:
          const Color(0xff6c5ce7),

      foregroundColor:
          Colors.white,

      elevation: 8,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
    );
  }

  // ===========================================================================
  // FLOATING PULSE AI CHAT BUTTON
  // ===========================================================================

  Widget buildAIChatFloatingButton() {
    return FloatingActionButton(
      heroTag:
          'pulse_ai_chat_fab',

      tooltip:
          'Pulse AI Chat',

      onPressed: () {
        Navigator.push(
          context,

          MaterialPageRoute(
            builder: (_) =>
                AIChatScreen(
              token:
                  widget.token,

              latestHealthRecord:
                  latestHealthRecord,
            ),
          ),
        );
      },

      child: const Icon(
        Symbols.chat_apps_script,
        size: 24,
      ),

      backgroundColor:
          const Color(0xff2d3748),

      foregroundColor:
          Colors.white,

      elevation: 8,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
    );
  }

  // ===========================================================================
  // SYNC BUTTON
  // ===========================================================================

  Widget _buildSyncButton() {
    return SizedBox(
      width:
          double.infinity,

      child:
          ElevatedButton.icon(
        onPressed:
            isSyncing
                ? null
                : syncHealthToBackend,

        icon: isSyncing
            ? const SizedBox(
                width: 17,
                height: 17,

                child:
                    CircularProgressIndicator(
                  color:
                      Colors.white,

                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons
                    .cloud_upload_outlined,
              ),

        label: Text(
          isSyncing
              ? 'Syncing...'
              : 'Push to Pulse AI Database',
        ),

        style:
            ElevatedButton.styleFrom(
          foregroundColor:
              Colors.white,

          backgroundColor:
              const Color(
            0xff9f6eff,
          ),

          padding:
              const EdgeInsets.symmetric(
            vertical: 15,
          ),

          elevation: 0,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // INFO TILE
  // ===========================================================================

  Widget _buildInfoTile(
    String title,
    String value,
  ) {
    return ListTile(
      dense: true,

      title: Text(
        title,

        style:
            const TextStyle(
          fontSize: 14,
          color:
              Colors.black54,
        ),
      ),

      trailing: Text(
        value,

        style:
            const TextStyle(
          fontSize: 15,
          fontWeight:
              FontWeight.bold,
          color:
              Colors.black87,
        ),
      ),
    );
  }
}
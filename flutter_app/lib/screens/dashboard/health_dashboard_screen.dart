import 'package:flutter/material.dart';

import '../../core/services/health_service.dart';
import '../../core/services/auth_manager.dart';
import 'record_health_screen.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() =>
      _HealthDashboardScreenState();
}

class _HealthDashboardScreenState
    extends State<HealthDashboardScreen> {
  Map<String, dynamic>? _healthData;

  bool _isLoading = true;
  bool _isSyncing = false;

  String _recordStatus = 'Loading health records...';
  String? _recordDate;

  // ---------------------------------------------------------------------------
  // DEMO DATA
  // ---------------------------------------------------------------------------

  static const Map<String, dynamic> _demoData = {
    'date': null,
    'steps': 0,
    'heartRate': 0,
    'floors': 0,
    'bloodOxygen': 0.0,
    'activeZoneMinutes': 0,
    'weight': 0.0,
    'source': 'Google Health',
    'email': null,
  };

  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _fetchHealthData();
  }

  // ---------------------------------------------------------------------------
  // FETCH GOOGLE HEALTH DATA
  // ---------------------------------------------------------------------------

  Future<void> _fetchHealthData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _recordStatus = 'Connecting to Google Health...';
      _recordDate = null;
    });

    try {
      // ---------------------------------------------------------------
      // 1. CONNECT TO GOOGLE HEALTH
      // ---------------------------------------------------------------

      final authorized = await HealthService.connect();

      if (!authorized) {
        if (!mounted) return;

        setState(() {
          _healthData = _demoData;
          _isLoading = false;
          _recordStatus = 'Google Health connection cancelled';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Google Health connection was cancelled.',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        return;
      }

      // ---------------------------------------------------------------
      // 2. FETCH ALL HEALTH HISTORY
      // ---------------------------------------------------------------

      if (!mounted) return;

      setState(() {
        _recordStatus = 'Fetching your latest health record...';
      });

      final history =
          await HealthService.getAllHealthHistory();

      final records =
          history['records'];

      if (records is! List || records.isEmpty) {
        if (!mounted) return;

        setState(() {
          _healthData = _demoData;
          _isLoading = false;
          _recordStatus = 'No health records found';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No health records were found for this Google account.',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        return;
      }

      // ---------------------------------------------------------------
      // 3. FIND TODAY'S RECORD
      // ---------------------------------------------------------------

      final today =
          _localDateKey(DateTime.now());

      Map<String, dynamic>? selectedRecord;

      for (final rawRecord in records) {
        if (rawRecord is! Map) continue;

        final record =
            Map<String, dynamic>.from(rawRecord);

        final recordDate =
            record['date']?.toString();

        if (recordDate == today) {
          selectedRecord = record;
          break;
        }
      }

      // ---------------------------------------------------------------
      // 4. IF NO TODAY RECORD, USE LATEST RECORD
      // ---------------------------------------------------------------

      bool isLatestFallback = false;

      if (selectedRecord == null) {
        final first = records.first;

        if (first is Map) {
          selectedRecord =
              Map<String, dynamic>.from(first);

          isLatestFallback = true;
        }
      }

      if (selectedRecord == null) {
        throw Exception(
          'Unable to read the latest health record.',
        );
      }

      // ---------------------------------------------------------------
      // 5. ADD EXTRA INFORMATION
      // ---------------------------------------------------------------

      selectedRecord['source'] =
          history['source'] ??
              'Google Health Cloud API';

      selectedRecord['platform'] =
          history['platform'];

      selectedRecord['email'] =
          history['email'];

      // ---------------------------------------------------------------
      // 6. UPDATE UI
      // ---------------------------------------------------------------

      if (!mounted) return;

      setState(() {
        _healthData = selectedRecord;
        _recordDate =
            selectedRecord?['date']?.toString();

        _recordStatus = isLatestFallback
            ? 'Latest available health record'
            : 'Today\'s health record';

        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        '[HealthDashboard] Error: $e',
      );

      if (!mounted) return;

      setState(() {
        _healthData = null;
        _isLoading = false;
        _recordStatus =
            'Unable to load Google Health data';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading health data: $e',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // LOCAL DATE KEY
  // ---------------------------------------------------------------------------

  String _localDateKey(DateTime date) {
    final year =
        date.year.toString().padLeft(4, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final day =
        date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // ---------------------------------------------------------------------------
  // FORMAT RECORDED DATE
  // ---------------------------------------------------------------------------

  String _formatRecordedDate(
    String? date,
  ) {
    if (date == null || date.isEmpty) {
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
        local.day.toString().padLeft(2, '0');

    final month =
        local.month.toString().padLeft(2, '0');

    final year =
        local.year.toString();

    return '$day/$month/$year';
  }

  // ---------------------------------------------------------------------------
  // SYNC TO BACKEND
  // ---------------------------------------------------------------------------

  Future<void> _syncToBackend() async {
    if (_healthData == null) return;

    if (!mounted) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final token =
          await AuthManager().getToken();

      if (token == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No auth token found. Please login first.',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        return;
      }

      final success =
          await HealthService.syncToBackend(token);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Health data synced successfully!'
                : '❌ Server sync failed',
          ),
          backgroundColor:
              success
                  ? Colors.teal
                  : Colors.redAccent,
          duration:
              const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sync error: $e',
          ),
          backgroundColor:
              Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSyncing = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // OPEN ALL RECORDS
  // ---------------------------------------------------------------------------

  void _openAllRecords() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const RecordHealthScreen(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xfff4f7f6),

      appBar: AppBar(
        title: const Text(
          'Pulse AI Cloud',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        backgroundColor:
            Colors.white,

        elevation: 0,

        actions: [
          // ---------------------------------------------------------
          // ALL RECORDS
          // ---------------------------------------------------------

          IconButton(
            tooltip: 'All Health Records',
            icon: const Icon(
              Icons.history_rounded,
              color:
                  Color(0xff9f6eff),
            ),
            onPressed:
                _isLoading
                    ? null
                    : _openAllRecords,
          ),

          // ---------------------------------------------------------
          // REFRESH
          // ---------------------------------------------------------

          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.cloud_download_rounded,
              color:
                  Color(0xff9f6eff),
            ),
            onPressed:
                _isLoading
                    ? null
                    : _fetchHealthData,
          ),
        ],
      ),

      // -----------------------------------------------------------------------
      // BODY
      // -----------------------------------------------------------------------

      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xff9f6eff),
              ),
            )
          : RefreshIndicator(
              onRefresh:
                  _fetchHealthData,

              color:
                  const Color(0xff9f6eff),

              child:
                  SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding:
                    const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,

                  children: [
                    // -------------------------------------------------------
                    // STATUS HEADER
                    // -------------------------------------------------------

                    _buildHealthHeader(),

                    const SizedBox(
                      height: 24,
                    ),

                    // -------------------------------------------------------
                    // RECORD DATE
                    // -------------------------------------------------------

                    _buildRecordDateCard(),

                    const SizedBox(
                      height: 20,
                    ),

                    // -------------------------------------------------------
                    // METRICS
                    // -------------------------------------------------------

                    GridView.count(
                      crossAxisCount: 2,

                      crossAxisSpacing: 16,

                      mainAxisSpacing: 16,

                      shrinkWrap: true,

                      physics:
                          const NeverScrollableScrollPhysics(),

                      children: [
                        _buildMetricCard(
                          'Steps',
                          '${_healthData?['steps'] ?? 0}',
                          'Daily total',
                          Icons
                              .directions_walk_rounded,
                          Colors.orange,
                        ),

                        _buildMetricCard(
                          'Heart Rate',
                          '${_healthData?['heartRate'] ?? 0} BPM',
                          'Latest reading',
                          Icons
                              .favorite_rounded,
                          Colors.redAccent,
                        ),

                        _buildMetricCard(
                          'Floors',
                          '${_healthData?['floors'] ?? 0}',
                          'Daily total',
                          Icons
                              .stairs_rounded,
                          Colors.purple,
                        ),

                        _buildMetricCard(
                          'SpO₂',
                          '${_healthData?['bloodOxygen'] ?? 0}%',
                          'Latest reading',
                          Icons.air_rounded,
                          Colors.teal,
                        ),

                        _buildMetricCard(
                          'Active Zone',
                          '${_healthData?['activeZoneMinutes'] ?? 0} min',
                          'Daily total',
                          Icons
                              .local_fire_department_rounded,
                          Colors.deepOrange,
                        ),

                        _buildMetricCard(
                          'Weight',
                          '${_healthData?['weight'] ?? 0} kg',
                          'Latest reading',
                          Icons
                              .monitor_weight_rounded,
                          Colors.blueGrey,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    // -------------------------------------------------------
                    // VIEW ALL RECORDS
                    // -------------------------------------------------------

                    _buildViewRecordsButton(),

                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEALTH HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHealthHeader() {
    final email =
        _healthData?['email']
            ?.toString();

    final source =
        _healthData?['source']
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
            BorderRadius.circular(24),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.all(10),

                decoration:
                    BoxDecoration(
                  color: Colors.white
                      .withOpacity(0.18),
                  shape:
                      BoxShape.circle,
                ),

                child: const Icon(
                  Icons
                      .health_and_safety_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              const Expanded(
                child: Text(
                  'Google Health Connected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.all(6),

                decoration:
                    const BoxDecoration(
                  color: Colors.white,
                  shape:
                      BoxShape.circle,
                ),

                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.teal,
                  size: 18,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          Text(
            _recordStatus,
            style: const TextStyle(
              color: Colors.white,
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
            style: const TextStyle(
              color: Colors.white70,
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
                  color: Colors.white70,
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

          const SizedBox(
            height: 16,
          ),

          // PUSH TO DATABASE

          SizedBox(
            width: double.infinity,

            child:
                ElevatedButton.icon(
              onPressed:
                  _isSyncing
                      ? null
                      : _syncToBackend,

              icon: _isSyncing
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child:
                          CircularProgressIndicator(
                        color:
                            Colors.purple,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons
                          .cloud_upload_outlined,
                      size: 17,
                    ),

              label: Text(
                _isSyncing
                    ? 'Syncing...'
                    : 'Push to Pulse AI Database',
              ),

              style:
                  ElevatedButton.styleFrom(
                foregroundColor:
                    Colors.purple,

                backgroundColor:
                    Colors.white,

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 13,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RECORD DATE CARD
  // ---------------------------------------------------------------------------

  Widget _buildRecordDateCard() {
    final date =
        _healthData?['date']
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
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: Colors.black
              .withOpacity(0.04),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.025),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.all(10),

            decoration:
                BoxDecoration(
              color: const Color(
                0xff9f6eff,
              ).withOpacity(0.10),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child: const Icon(
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
                      ? 'Today\'s Health Record'
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
                      .withOpacity(0.10)
                  : Colors.orange
                      .withOpacity(0.10),

              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),

            child: Text(
              isToday
                  ? 'TODAY'
                  : 'LATEST',

              style: TextStyle(
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

  // ---------------------------------------------------------------------------
  // VIEW ALL RECORDS BUTTON
  // ---------------------------------------------------------------------------

  Widget _buildViewRecordsButton() {
    return OutlinedButton.icon(
      onPressed: _openAllRecords,

      icon: const Icon(
        Icons.history_rounded,
      ),

      label: const Text(
        'View All Health Records',
      ),

      style:
          OutlinedButton.styleFrom(
        foregroundColor:
            const Color(0xff9f6eff),

        side: const BorderSide(
          color: Color(0xff9f6eff),
        ),

        padding:
            const EdgeInsets.symmetric(
          vertical: 15,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // METRIC CARD
  // ---------------------------------------------------------------------------

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.025),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,

        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Container(
                padding:
                    const EdgeInsets.all(8),

                decoration:
                    BoxDecoration(
                  color: accentColor
                      .withOpacity(0.12),

                  shape:
                      BoxShape.circle,
                ),

                child: Icon(
                  icon,
                  color:
                      accentColor,
                  size: 22,
                ),
              ),

              Flexible(
                child: Text(
                  subtitle,
                  textAlign:
                      TextAlign.right,

                  style:
                      const TextStyle(
                    color:
                        Colors.black26,
                    fontSize: 9,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                value,
                style:
                    const TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xff2d3748),
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w500,
                  color: Colors.black
                      .withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
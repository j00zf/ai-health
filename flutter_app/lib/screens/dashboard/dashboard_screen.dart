import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'health_dashboard_screen.dart' hide HealthService;
import 'record_health_screen.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/auth_manager.dart';
import '../../core/services/health_service.dart';
import '../auth/welcome_screen.dart';

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

class _DashboardScreenState extends State<DashboardScreen> {
  // ---------------------------------------------------------------------------
  // DASHBOARD STATE
  // ---------------------------------------------------------------------------

  bool isLoading = true;
  bool isHealthLoading = true;
  bool isConnectingHealth = false;

  Map<String, dynamic>? dashboard;

  List<Map<String, dynamic>> healthRecords = [];

  Map<String, dynamic>? latestHealthRecord;

  String? errorMessage;
  String? healthErrorMessage;

  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    loadDashboard();
  }

  // ---------------------------------------------------------------------------
  // LOAD MAIN DASHBOARD
  // ---------------------------------------------------------------------------

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

      setState(() {
        dashboard =
            response.data["data"]
                as Map<String, dynamic>?;

        isLoading = false;
      });

      // Load Google Health after the main dashboard.
      await loadHealthOverview();
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Failed to load dashboard'),
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

  // ---------------------------------------------------------------------------
  // LOAD GOOGLE HEALTH OVERVIEW
  // ---------------------------------------------------------------------------

  Future<void> loadHealthOverview() async {
    if (!mounted) return;

    setState(() {
      isHealthLoading = true;
      healthErrorMessage = null;
    });

    try {
      /*
       * IMPORTANT:
       *
       * We do NOT modify HealthService.
       *
       * HealthService already provides:
       *
       * getAllHealthHistory()
       *
       * which returns:
       *
       * [
       *   newest day,
       *   older day,
       *   older day,
       *   ...
       * ]
       *
       * Therefore:
       *
       * records.first = latest available health record.
       */

      if (!HealthService.isConnected) {
        if (!mounted) return;

        setState(() {
          healthRecords = [];
          latestHealthRecord = null;
          isHealthLoading = false;
        });

        return;
      }

      final history =
          await HealthService
              .getAllHealthHistory();

      final rawRecords =
          history['records'];

      final records =
          rawRecords is List
              ? rawRecords
                  .whereType<Map>()
                  .map(
                    (record) =>
                        Map<String, dynamic>.from(
                      record,
                    ),
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
      });
    } catch (e) {
      debugPrint(
        'Health overview error: $e',
      );

      if (!mounted) return;

      setState(() {
        isHealthLoading = false;
        healthErrorMessage =
            "Unable to load Google Health data";
      });
    }
  }

  // ---------------------------------------------------------------------------
  // CONNECT GOOGLE HEALTH
  // ---------------------------------------------------------------------------

  Future<void> connectGoogleHealth() async {
    if (isConnectingHealth) return;

    setState(() {
      isConnectingHealth = true;
    });

    try {
      final connected =
          await HealthService.connect();

      if (!mounted) return;

      if (!connected) {
        setState(() {
          isConnectingHealth = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
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

      await loadHealthOverview();

      if (!mounted) return;

      setState(() {
        isConnectingHealth = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
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
      });

      ScaffoldMessenger.of(context).showSnackBar(
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

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------

  Future<void> _handleLogout() async {
    await AuthManager().clearToken();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const WelcomeScreen(),
      ),
      (route) => false,
    );
  }

  // ---------------------------------------------------------------------------
  // FORCE LOGOUT
  // ---------------------------------------------------------------------------

  Future<void> _forceLogout() async {
    await AuthManager().clearToken();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Session expired. Please login again.",
        ),
        backgroundColor:
            Colors.orange,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const WelcomeScreen(),
      ),
      (route) => false,
    );
  }

  // ---------------------------------------------------------------------------
  // NUMBER HELPERS
  // ---------------------------------------------------------------------------

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

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

  // ---------------------------------------------------------------------------
  // AVERAGE
  // ---------------------------------------------------------------------------

  double _average(
    String key,
  ) {
    if (healthRecords.isEmpty) {
      return 0;
    }

    double total = 0;
    int count = 0;

    for (final record in healthRecords) {
      final value =
          _toDouble(record[key]);

      /*
       * Ignore missing values.
       *
       * Example:
       * If SpO₂ was not recorded on a particular
       * day, that day must not become 0% in the
       * average.
       */

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

  // ---------------------------------------------------------------------------
  // FORMAT DATE
  // ---------------------------------------------------------------------------

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
      );

      final today =
          DateTime.now();

      if (date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) {
        return "Today • ${date.day.toString().padLeft(2, '0')}/"
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

      return "${months[date.month - 1]} "
          "${date.day}, "
          "${date.year}";
    } catch (_) {
      return value.toString();
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

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

    final user =
        dashboard?["user"] ?? {};

    final profile =
        dashboard?["profile"] ?? {};

    final stats =
        dashboard?["stats"] ?? {};

    final devices =
        dashboard?["devices"] ?? {};

    final healthConnected =
        HealthService.isConnected ||
        devices["healthConnected"] == true;

    return Scaffold(
      backgroundColor:
          const Color(0xfff4f7f6),

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
            icon: const Icon(
              Icons.logout_rounded,
              color:
                  Colors.redAccent,
            ),
            tooltip: "Logout",
            onPressed:
                _handleLogout,
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          await loadDashboard();

          if (HealthService.isConnected) {
            await loadHealthOverview();
          }
        },

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
              // ================================================================
              // USER PROFILE
              // ================================================================

              _buildProfileHeader(
                user,
              ),

              const SizedBox(
                height: 24,
              ),

              // ================================================================
              // PROFILE INFORMATION
              // ================================================================

              _buildProfileCard(
                profile,
              ),

              const SizedBox(
                height: 22,
              ),

              // ================================================================
              // APPLICATION STATS
              // ================================================================

              _buildApplicationStats(
                stats,
              ),

              const SizedBox(
                height: 28,
              ),

              // ================================================================
              // GOOGLE HEALTH SECTION
              // ================================================================

              _buildHealthSectionHeader(),

              const SizedBox(
                height: 12,
              ),

              if (!healthConnected)
                _buildConnectHealthCard()
              else if (isHealthLoading)
                _buildHealthLoadingCard()
              else if (latestHealthRecord != null) ...[
                // --------------------------------------------------------------
                // LATEST RECORD
                // --------------------------------------------------------------

                _buildLatestHealthCard(),

                const SizedBox(
                  height: 26,
                ),

                // --------------------------------------------------------------
                // AVERAGES
                // --------------------------------------------------------------

                _buildAverageSection(),
              ] else
                _buildNoHealthDataCard(),

              const SizedBox(
                height: 24,
              ),

              // ================================================================
              // HEALTH HISTORY
              // ================================================================

              _buildHealthHistoryButton(),

              const SizedBox(
                height: 12,
              ),

              // ================================================================
              // FULL HEALTH DASHBOARD
              // ================================================================

              _buildOpenHealthDashboardButton(),

              const SizedBox(
                height: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PROFILE HEADER
  // ---------------------------------------------------------------------------

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

            child:
                photo == null ||
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

            style:
                TextStyle(
              color:
                  Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PROFILE CARD
  // ---------------------------------------------------------------------------

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
            profile["activityLevel"]
                    ?.toString() ??
                "-",
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // APPLICATION STATS
  // ---------------------------------------------------------------------------

  Widget _buildApplicationStats(
    Map<String, dynamic> stats,
  ) {
    return Row(
      children: [
        Expanded(
          child:
              _buildStatCard(
            icon:
                Icons.directions_walk,
            color:
                Colors.orange,
            value:
                stats["steps"]
                        ?.toString() ??
                    "0",
            label:
                "Steps",
          ),
        ),

        const SizedBox(
          width: 14,
        ),

        Expanded(
          child:
              _buildStatCard(
            icon:
                Icons.local_fire_department,
            color:
                Colors.redAccent,
            value:
                stats["calories"]
                        ?.toString() ??
                    "0",
            label:
                "Calories",
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HEALTH SECTION HEADER
  // ---------------------------------------------------------------------------

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
                style: TextStyle(
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
                style: TextStyle(
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

  // ---------------------------------------------------------------------------
  // CONNECT CARD
  // ---------------------------------------------------------------------------

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

                child: const Icon(
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

              label:
                  Text(
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
                    const EdgeInsets.symmetric(
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

  // ---------------------------------------------------------------------------
  // LOADING CARD
  // ---------------------------------------------------------------------------

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

      child: const Column(
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

  // ---------------------------------------------------------------------------
  // LATEST HEALTH RECORD
  // ---------------------------------------------------------------------------

  Widget _buildLatestHealthCard() {
    final record =
        latestHealthRecord!;

    final date =
        record["date"];

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Container(
          padding:
              const EdgeInsets.all(
            20,
          ),

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

                blurRadius:
                    18,

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
                        const EdgeInsets
                            .symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white
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

              // --------------------------------------------------------------
              // LATEST METRICS
              // --------------------------------------------------------------

              GridView.count(
                crossAxisCount: 2,

                crossAxisSpacing:
                    10,

                mainAxisSpacing:
                    10,

                childAspectRatio:
                    1.55,

                shrinkWrap:
                    true,

                physics:
                    const NeverScrollableScrollPhysics(),

                children: [
                  _buildHealthMetric(
                    icon:
                        Icons
                            .directions_walk_rounded,
                    title:
                        "Steps",
                    value:
                        "${_toInt(record["steps"])}",
                    unit:
                        "steps",
                  ),

                  _buildHealthMetric(
                    icon:
                        Icons
                            .favorite_rounded,
                    title:
                        "Heart Rate",
                    value:
                        "${_toInt(record["heartRate"])}",
                    unit:
                        "BPM",
                  ),

                  _buildHealthMetric(
                    icon:
                        Icons
                            .stairs_rounded,
                    title:
                        "Floors",
                    value:
                        "${_toInt(record["floors"])}",
                    unit:
                        "floors",
                  ),

                  _buildHealthMetric(
                    icon:
                        Icons.air_rounded,
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
                    icon:
                        Icons
                            .local_fire_department_rounded,
                    title:
                        "Active Zone",
                    value:
                        "${_toInt(record["activeZoneMinutes"])}",
                    unit:
                        "min",
                  ),

                  _buildHealthMetric(
                    icon:
                        Icons
                            .monitor_weight_rounded,
                    title:
                        "Weight",
                    value:
                        _toDouble(
                          record[
                              "weight"],
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
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HEALTH METRIC
  // ---------------------------------------------------------------------------

  Widget _buildHealthMetric({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        12,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white.withOpacity(
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
                            TextOverflow
                                .ellipsis,
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
                          const EdgeInsets
                              .only(
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

  // ---------------------------------------------------------------------------
  // AVERAGE SECTION
  // ---------------------------------------------------------------------------

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
                  const EdgeInsets
                      .symmetric(
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
          icon:
              Icons
                  .directions_walk_rounded,
          title:
              "Average Steps",
          value:
              _average(
                "steps",
              ).round().toString(),
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
              _average(
                "heartRate",
              ).toStringAsFixed(
                1,
              ),
          unit:
              "BPM",
          color:
              Colors.redAccent,
        ),

        _buildAverageMetric(
          icon:
              Icons.stairs_rounded,
          title:
              "Average Floors",
          value:
              _average(
                "floors",
              ).toStringAsFixed(
                1,
              ),
          unit:
              "floors / day",
          color:
              Colors.deepPurple,
        ),

        _buildAverageMetric(
          icon:
              Icons.air_rounded,
          title:
              "Average SpO₂",
          value:
              _average(
                "bloodOxygen",
              ).toStringAsFixed(
                1,
              ),
          unit:
              "%",
          color:
              Colors.teal,
        ),

        _buildAverageMetric(
          icon:
              Icons
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
          icon:
              Icons
                  .monitor_weight_rounded,
          title:
              "Average Weight",
          value:
              _average(
                "weight",
              ).toStringAsFixed(
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

  // ---------------------------------------------------------------------------
  // AVERAGE METRIC CARD
  // ---------------------------------------------------------------------------

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
              color:
                  color.withOpacity(
                0.10,
              ),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child: Icon(
              icon,
              color:
                  color,
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

  // ---------------------------------------------------------------------------
  // NO HEALTH DATA
  // ---------------------------------------------------------------------------

  Widget _buildNoHealthDataCard() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        25,
      ),

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

          const Text(
            "Your Google Health account is connected, "
            "but no recorded health data was found.",
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize: 11,
              color:
                  Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HISTORY BUTTON
  // ---------------------------------------------------------------------------

  Widget _buildHealthHistoryButton() {
    return SizedBox(
      width:
          double.infinity,

      child:
          OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const RecordHealthScreen(),
            ),
          ).then(
            (_) =>
                loadHealthOverview(),
          );
        },

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

  // ---------------------------------------------------------------------------
  // OPEN HEALTH DASHBOARD
  // ---------------------------------------------------------------------------

  Widget _buildOpenHealthDashboardButton() {
    return SizedBox(
      width:
          double.infinity,

      child:
          ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const HealthDashboardScreen(),
            ),
          ).then(
            (_) =>
                loadHealthOverview(),
          );
        },

        icon: const Icon(
          Icons.analytics_rounded,
        ),

        label: const Text(
          "Open Detailed Health Dashboard",
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
              const EdgeInsets.symmetric(
            vertical: 16,
          ),

          elevation: 0,

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

  // ---------------------------------------------------------------------------
  // INFO TILE
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // STAT CARD
  // ---------------------------------------------------------------------------

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Card(
      elevation: 0,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(
          20,
        ),

        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color:
                  color,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              value,
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

            Text(label),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../dashboard/health_averages_screen.dart';

import '../../features/ml/ml_health_details_screen.dart';
import '../../features/ml/ml_health_history_screen.dart';

/// ===============================================================
/// HEALTH SIDEBAR
/// ===============================================================
///
/// Main navigation sidebar for Pulse AI.
///
/// ML Health navigation:
/// - Dashboard callback opens ML dashboard
/// - Details and History are opened directly
///
/// ===============================================================

class HealthSidebar extends StatelessWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> profile;

  final bool healthConnected;

  final String token;

  final VoidCallback onDashboard;
  final VoidCallback onAccount;
  final VoidCallback onAllHealthHistory;
  final VoidCallback onSyncHealth;
  final VoidCallback onLogout;

  /// ML Health Dashboard callback
  final VoidCallback onMlHealthDashboard;

  /// ML Health Details callback
  final VoidCallback onMlHealthDetails;

  /// ML Health History callback
  final VoidCallback onMlHealthHistory;

  const HealthSidebar({
    super.key,
    required this.user,
    required this.profile,
    required this.healthConnected,
    required this.token,
    required this.onDashboard,
    required this.onAccount,
    required this.onAllHealthHistory,
    required this.onSyncHealth,
    required this.onLogout,
    required this.onMlHealthDashboard,
    required this.onMlHealthDetails,
    required this.onMlHealthHistory,
  });

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    final name =
        user["name"]?.toString().trim().isNotEmpty == true
            ? user["name"].toString()
            : "User";

    final email = user["email"]?.toString() ?? "";

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              name: name,
              email: email,
            ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // =====================================================
                  // MAIN
                  // =====================================================

                  _buildSectionLabel("MAIN"),

                  _sidebarItem(
                    icon: Icons.dashboard_rounded,
                    title: "Dashboard",
                    subtitle: "Health overview and latest data",
                    onTap: () {
                      Navigator.pop(context);
                      onDashboard();
                    },
                  ),

                  _sidebarItem(
                    icon: Icons.person_outline_rounded,
                    title: "My Profile",
                    subtitle: "Manage your personal & health details",
                    onTap: () {
                      Navigator.pop(context);
                      onAccount();
                    },
                  ),

                  _sidebarItem(
                    icon: Icons.history_rounded,
                    title: "All Health History",
                    subtitle: "Every available recorded day",
                    onTap: () {
                      Navigator.pop(context);
                      onAllHealthHistory();
                    },
                  ),

                  _sidebarItem(
                    icon: Icons.insights_rounded,
                    title: "Weekly & Monthly Averages",
                    subtitle: "View health trends and averages",
                    onTap: () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const HealthAveragesScreen(),
                        ),
                      );
                    },
                  ),

                  _sidebarItem(
                    icon: Icons.monitor_heart_rounded,
                    title: "Resting BPM",
                    subtitle: "Daily resting heart-rate history",
                    onTap: () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const HealthAveragesScreen(
                            initialMetric: "restingHeartRate",
                          ),
                        ),
                      );
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Divider(),
                  ),
// =====================================================
// ML HEALTH
// =====================================================

_buildSectionLabel("WELLNESS & STRESS"),

_sidebarItem(
  icon: Icons.auto_graph_rounded,
  title: "Wellness Insights",
  subtitle: "Current AI-powered wellness analysis",
  color: const Color(0xff6c5ce7),
  onTap: () {
    Navigator.pop(context);
    onMlHealthDashboard();
  },
),

_sidebarItem(
  icon: Icons.health_and_safety_rounded,
  title: "Wellness Details",
  subtitle: "Detailed wellness scores and insights",
  color: const Color(0xff6c5ce7),
  onTap: () {
    Navigator.pop(context);
    onMlHealthDetails();
  },
),

_sidebarItem(
  icon: Icons.trending_up_rounded,
  title: "Improvement History",
  subtitle: "Track your health improvements",
  color: const Color(0xff6c5ce7),
  onTap: () {
    Navigator.pop(context);
    onMlHealthHistory();
  },
),                  // =====================================================
                  // HEALTH CONNECTION
                  // =====================================================

                  _buildSectionLabel("HEALTH CONNECTION"),

                  _sidebarItem(
                    icon: healthConnected
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    title: "Google Health",
                    subtitle: healthConnected
                        ? "Connected and ready to sync"
                        : "Connect Google Health",
                    color: healthConnected
                        ? Colors.green
                        : Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      onSyncHealth();
                    },
                  ),

                  _sidebarItem(
                    icon: Icons.refresh_rounded,
                    title: "Sync Google Health",
                    subtitle: "Refresh your latest health data",
                    color: const Color(0xff2563eb),
                    onTap: () {
                      Navigator.pop(context);
                      onSyncHealth();
                    },
                  ),

                  const SizedBox(height: 8),

                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: Divider(),
                  ),

                  // =====================================================
                  // LOGOUT
                  // =====================================================

                  _sidebarItem(
                    icon: Icons.logout_rounded,
                    title: "Logout",
                    subtitle: "Sign out from Pulse AI",
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      onLogout();
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // HEADER
  // ===============================================================

  Widget _buildHeader({
    required String name,
    required String email,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xff6c5ce7),
            Color(0xff9f6eff),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),

          if (email.isNotEmpty) ...[
            const SizedBox(height: 3),

            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  healthConnected
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  color: Colors.white,
                  size: 17,
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: Text(
                    healthConnected
                        ? "Google Health connected"
                        : "Google Health not connected",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // SECTION LABEL
  // ===============================================================

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        8,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // SIDEBAR ITEM
  // ===============================================================

  Widget _sidebarItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color color = const Color(0xff374151),
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 2,
      ),

      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),

      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: color,
        ),
      ),

      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black45,
              ),
            ),

      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: Colors.black26,
      ),

      onTap: onTap,
    );
  }

  // ===============================================================
  // FOOTER
  // ===============================================================

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.favorite_rounded,
            size: 14,
            color: Colors.grey.shade400,
          ),

          const SizedBox(width: 7),

          Text(
            "Pulse AI",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),

          const Spacer(),

          Text(
            "Wellness & Stress",
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
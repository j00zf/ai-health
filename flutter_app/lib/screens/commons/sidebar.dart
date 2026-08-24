import 'package:flutter/material.dart';

import '../dashboard/health_averages_screen.dart';

/// Standalone sidebar for the Pulse AI dashboard.
///
/// This widget contains only the sidebar UI and navigation callbacks.
/// Dashboard/business logic stays inside DashboardScreen.
class HealthSidebar extends StatelessWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> profile;
  final bool healthConnected;

  final VoidCallback onDashboard;
  final VoidCallback onAccount;
  final VoidCallback onAllHealthHistory;
  final VoidCallback onSyncHealth;
  final VoidCallback onLogout;

  const HealthSidebar({
    super.key,
    required this.user,
    required this.profile,
    required this.healthConnected,
    required this.onDashboard,
    required this.onAccount,
    required this.onAllHealthHistory,
    required this.onSyncHealth,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final name = user["name"]?.toString() ?? "User";
    final email = user["email"]?.toString() ?? "";

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ===============================================================
            // PROFILE HEADER
            // ===============================================================
            Container(
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
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 27,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.health_and_safety_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 2),
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

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Icon(
                        healthConnected
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_off_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
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
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ===============================================================
            // DASHBOARD
            // ===============================================================
            _sidebarItem(
              icon: Icons.dashboard_rounded,
              title: "Dashboard",
              onTap: () {
                Navigator.pop(context);
                onDashboard();
              },
            ),

            // ===============================================================
            // MY PROFILE
            // ===============================================================
            _sidebarItem(
              icon: Icons.person_outline_rounded,
              title: "My Profile",
              subtitle: "Manage your personal & health details",
              onTap: () {
                Navigator.pop(context);
                onAccount();
              },
            ),

            // ===============================================================
            // ALL HEALTH HISTORY
            // ===============================================================
            _sidebarItem(
              icon: Icons.history_rounded,
              title: "All Health History",
              subtitle: "Every available recorded day",
              onTap: () {
                Navigator.pop(context);
                onAllHealthHistory();
              },
            ),

            // ===============================================================
            // WEEKLY / MONTHLY AVERAGES
            // ===============================================================
            _sidebarItem(
              icon: Icons.insights_rounded,
              title: "Weekly & Monthly Averages",
              subtitle: "Trends from the first available entry",
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HealthAveragesScreen(),
                  ),
                );
              },
            ),

            // ===============================================================
            // RESTING HEART RATE
            // ===============================================================
            _sidebarItem(
              icon: Icons.monitor_heart_rounded,
              title: "Resting BPM",
              subtitle: "Daily resting heart-rate history",
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HealthAveragesScreen(
                      initialMetric: "restingHeartRate",
                    ),
                  ),
                );
              },
            ),

            const Divider(
              height: 24,
              indent: 16,
              endIndent: 16,
            ),

            // ===============================================================
            // SYNC
            // ===============================================================
            _sidebarItem(
              icon: Icons.refresh_rounded,
              title: "Sync Google Health",
              subtitle: "Refresh all available history",
              onTap: () {
                Navigator.pop(context);
                onSyncHealth();
              },
            ),

            // ===============================================================
            // LOGOUT
            // ===============================================================
            _sidebarItem(
              icon: Icons.logout_rounded,
              title: "Logout",
              color: Colors.redAccent,
              onTap: () {
                Navigator.pop(context);
                onLogout();
              },
            ),

            const Spacer(),

            // ===============================================================
            // FOOTER
            // ===============================================================
            Padding(
              padding: const EdgeInsets.only(
                bottom: 18,
                left: 20,
                right: 20,
              ),
              child: Text(
                "Pulse AI",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // SIDEBAR ITEM
  // =========================================================================

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
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(11),
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
}
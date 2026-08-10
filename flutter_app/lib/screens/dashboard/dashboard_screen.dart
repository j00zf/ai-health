import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'health_dashboard_screen.dart';
import 'record_health_screen.dart';          // ← NEW
import '../../core/constants/api_constants.dart';
import '../../core/services/auth_manager.dart';
import '../auth/welcome_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String token;

  const DashboardScreen({
    super.key,
    required this.token,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;
  Map<String, dynamic>? dashboard;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await Dio().get(
        "${ApiConstants.baseUrl}/dashboard",
        options: Options(
          headers: {
            "Authorization": "Bearer ${widget.token}",
          },
        ),
      );

      if (!mounted) return;

      setState(() {
        dashboard = response.data["data"] as Map<String, dynamic>?;
        isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      if (e.response?.statusCode == 401) {
        debugPrint("Token expired or invalid (401). Logging out...");
        await _forceLogout();
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage = "Failed to load dashboard";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load dashboard'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = "Something went wrong";
      });

      debugPrint('Dashboard load error: $e');
    }
  }

  Future<void> _handleLogout() async {
    await AuthManager().clearToken();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _forceLogout() async {
    await AuthManager().clearToken();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Session expired. Please login again."),
        backgroundColor: Colors.orange,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xff9f6eff)),
        ),
      );
    }

    final user = dashboard?["user"] ?? {};
    final profile = dashboard?["profile"] ?? {};
    final stats = dashboard?["stats"] ?? {};
    final devices = dashboard?["devices"] ?? {};

    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      appBar: AppBar(
        title: const Text(
          "Pulse AI",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: "Logout",
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadDashboard,
        color: const Color(0xff9f6eff),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= Profile Header =================
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: user["photoUrl"] != null &&
                              user["photoUrl"].toString().isNotEmpty
                          ? NetworkImage(user["photoUrl"])
                          : null,
                      child: (user["photoUrl"] == null ||
                              user["photoUrl"].toString().isEmpty)
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user["name"] ?? "Unknown User",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user["email"] ?? "",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ================= Profile Card =================
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _buildInfoTile("Nickname", profile["nickname"] ?? "-"),
                      _buildInfoTile("Age", profile["age"]?.toString() ?? "-"),
                      _buildInfoTile("BMI", profile["bmi"]?.toString() ?? "-"),
                      _buildInfoTile("Health Goal", profile["healthGoal"] ?? "-"),
                      _buildInfoTile(
                          "Activity Level", profile["activityLevel"] ?? "-"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ================= Stats Row =================
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.directions_walk,
                      color: Colors.orange,
                      value: stats["steps"]?.toString() ?? "0",
                      label: "Steps",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.local_fire_department,
                      color: Colors.redAccent,
                      value: stats["calories"]?.toString() ?? "0",
                      label: "Calories",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ================= Health Connect Card =================
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.favorite, color: Colors.red, size: 28),
                  title: const Text(
                    "Google Health Connect",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    devices["healthConnected"] == true
                        ? "Connected • View Details"
                        : "Tap to Connect",
                  ),
                  trailing: Icon(
                    devices["healthConnected"] == true
                        ? Icons.chevron_right_rounded
                        : Icons.link,
                    color: devices["healthConnected"] == true
                        ? Colors.green
                        : Colors.blue,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HealthDashboardScreen(),
                      ),
                    ).then((_) => loadDashboard());
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ================= NEW: View All Health Records =================
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.history_rounded,
                      color: Color(0xff9f6eff), size: 28),
                  title: const Text(
                    "All Health Records",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text("View complete history of synced data"),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Color(0xff9f6eff)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecordHealthScreen(token: widget.token),
                      ),
                    ).then((_) => loadDashboard());
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ================= Open Health Dashboard Button =================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.analytics_rounded),
                  label: const Text("Open Health Dashboard"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xff9f6eff),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HealthDashboardScreen(),
                      ),
                    ).then((_) => loadDashboard());
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      dense: true,
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: Colors.black54),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}
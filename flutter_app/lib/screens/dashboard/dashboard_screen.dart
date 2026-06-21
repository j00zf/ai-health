import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'health_dashboard_screen.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/health_service.dart';

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

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final response = await Dio().get(
        "${ApiConstants.baseUrl}/dashboard",
        options: Options(
          headers: {
            "Authorization": "Bearer ${widget.token}",
          },
        ),
      );

      setState(() {
        dashboard = response.data["data"] as Map<String, dynamic>?;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Dashboard load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load dashboard')),
        );
      }
    }
  }

  // 🚪 Handled Logout Routine
  void _handleLogout() {
    // If your app uses an AuthManager to persist the session tokens, wipe it here:
    // AuthManager().clearToken(); 
    
    // Pop completely off the stack back to your Welcome Screen/Login interface
    Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = dashboard?["user"] ?? {};
    final profile = dashboard?["profile"] ?? {};
    final stats = dashboard?["stats"] ?? {};
    final devices = dashboard?["devices"] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pulse AI"),
        // 🚀 ADDED: Logout Button inside Action Area
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: "Logout",
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: user["photoUrl"] != null &&
                            user["photoUrl"].toString().isNotEmpty
                        ? NetworkImage(user["photoUrl"])
                        : null,
                    child: (user["photoUrl"] == null ||
                            user["photoUrl"].toString().isEmpty)
                        ? const Icon(Icons.person, size: 50)
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
                  Text(
                    user["email"] ?? "",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Profile Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListSideItem("Nickname", profile["nickname"] ?? "-"),
                    ListSideItem("Age", profile["age"]?.toString() ?? "-"),
                    ListSideItem("BMI", profile["bmi"]?.toString() ?? "-"),
                    ListSideItem("Health Goal", profile["healthGoal"] ?? "-"),
                    ListSideItem("Activity Level", profile["activityLevel"] ?? "-"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.directions_walk, size: 32, color: Colors.orange),
                          const SizedBox(height: 12),
                          Text(
                            stats["steps"]?.toString() ?? "0",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text("Steps"),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.local_fire_department, size: 32, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Text(
                            stats["calories"]?.toString() ?? "0",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text("Calories"),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Health Connect Status
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                ),
                title: const Text("Google Health Connect"),
                subtitle: Text(
                  devices["healthConnected"] == true ? "Connected • View Details" : "Tap to Connect",
                ),
                trailing: Icon(
                  devices["healthConnected"] == true ? Icons.chevron_right_rounded : Icons.link,
                  color: devices["healthConnected"] == true ? Colors.green : Colors.blue,
                ),
                onTap: () async {
                  // 🚀 ROUTING: Seamlessly forward them directly to the metrics viewer layout page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HealthDashboardScreen(),
                    ),
                  ).then((_) => loadDashboard()); // Reload status after return
                },
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.analytics_rounded),
                label: const Text("Open Health Dashboard Screen"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xff9f6eff),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HealthDashboardScreen()),
                  ).then((_) => loadDashboard());
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget ListSideItem(String title, String data) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
      trailing: Text(data, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
      dense: true,
    );
  }
}
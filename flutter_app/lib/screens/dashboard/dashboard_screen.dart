import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';

import '../../core/services/health_service.dart'; // Adjust path as needed

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
                    ListTile(
                      title: const Text("Nickname"),
                      subtitle: Text(profile["nickname"] ?? "-"),
                    ),
                    ListTile(
                      title: const Text("Age"),
                      subtitle: Text(profile["age"]?.toString() ?? "-"),
                    ),
                    ListTile(
                      title: const Text("BMI"),
                      subtitle: Text(profile["bmi"]?.toString() ?? "-"),
                    ),
                    ListTile(
                      title: const Text("Health Goal"),
                      subtitle: Text(profile["healthGoal"] ?? "-"),
                    ),
                    ListTile(
                      title: const Text("Activity Level"),
                      subtitle: Text(profile["activityLevel"] ?? "-"),
                    ),
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
                          const Icon(Icons.directions_walk, size: 32),
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
                          const Icon(Icons.local_fire_department, size: 32),
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
    title: const Text(
      "Google Health Connect",
    ),
    subtitle: Text(
      devices["healthConnected"] == true
          ? "Connected"
          : "Tap to Connect",
    ),
    trailing: Icon(
      devices["healthConnected"] == true
          ? Icons.check_circle
          : Icons.link,
      color: devices["healthConnected"] == true
          ? Colors.green
          : Colors.blue,
    ),
    onTap: () async {
      try {
        bool granted =
            await HealthService.connect();

        if (!granted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  "Health permissions denied",
                ),
              ),
            );
          }
          return;
        }

        await HealthService.syncToBackend(
          widget.token,
        );

        await loadDashboard();

        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                "Health Connect linked successfully",
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    },
  ),
),
            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sync),
                label: const Text("Sync Health Data"),
                onPressed: () async {
                  try {
                    await HealthService.connect();
                    await HealthService.syncToBackend(widget.token);
                    await loadDashboard();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Health Data Synced")),
                      );
                    }
                  } catch (e) {
                    debugPrint('Sync error: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Sync failed")),
                      );
                    }
                  }
                },
              ),
            ),

            const SizedBox(height: 12),

            
          ],
        ),
      ),
    );
  }
}
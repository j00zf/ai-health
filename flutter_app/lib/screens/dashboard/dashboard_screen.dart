import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../devices/my_devices_screen.dart';
import '../../core/constants/api_constants.dart';
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
    extends State<DashboardScreen> {

  bool isLoading = true;

  Map<String, dynamic>? dashboard;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {

      final response =
          await Dio().get(
  "${ApiConstants.baseUrl}/dashboard",
        options: Options(
          headers: {
            "Authorization":
                "Bearer ${widget.token}",
          },
        ),
      );

      setState(() {
        dashboard =
            response.data["data"];
        isLoading = false;
      });

    } catch (e) {

      setState(() {
        isLoading = false;
      });

      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pulse AI",
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          children: [

            CircleAvatar(
              radius: 50,
              backgroundImage:
                  user["photoUrl"] != null &&
                          user["photoUrl"]
                              .toString()
                              .isNotEmpty
                      ? NetworkImage(
                          user["photoUrl"])
                      : null,
              child:
                  user["photoUrl"] == null ||
                          user["photoUrl"]
                              .toString()
                              .isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 50,
                        )
                      : null,
            ),

            const SizedBox(
              height: 16,
            ),

            Text(
              user["name"] ??
                  "Unknown User",
              style: const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            Text(
              user["email"] ?? "",
            ),

            const SizedBox(
              height: 24,
            ),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                        16),
                child: Column(
                  children: [

                    ListTile(
                      title:
                          const Text(
                        "Nickname",
                      ),
                      subtitle: Text(
                        profile[
                                "nickname"] ??
                            "-",
                      ),
                    ),

                    ListTile(
                      title:
                          const Text(
                        "Age",
                      ),
                      subtitle: Text(
                        profile["age"]
                                ?.toString() ??
                            "-",
                      ),
                    ),

                    ListTile(
                      title:
                          const Text(
                        "BMI",
                      ),
                      subtitle: Text(
                        profile["bmi"]
                                ?.toString() ??
                            "-",
                      ),
                    ),

                    ListTile(
                      title:
                          const Text(
                        "Health Goal",
                      ),
                      subtitle: Text(
                        profile[
                                "healthGoal"] ??
                            "-",
                      ),
                    ),

                    ListTile(
                      title:
                          const Text(
                        "Activity Level",
                      ),
                      subtitle: Text(
                        profile[
                                "activityLevel"] ??
                            "-",
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Row(
              children: [

                Expanded(
                  child: Card(
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .all(16),
                      child: Column(
                        children: [

                          const Icon(
                            Icons
                                .directions_walk,
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            stats["steps"]
                                    ?.toString() ??
                                "0",
                          ),

                          const Text(
                            "Steps",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Card(
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .all(16),
                      child: Column(
                        children: [

                          const Icon(
                            Icons
                                .local_fire_department,
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            stats["calories"]
                                    ?.toString() ??
                                "0",
                          ),

                          const Text(
                            "Calories",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.watch,
                ),

                title: const Text(
                  "Fitbit",
                ),

                subtitle: Text(
                  devices[
                              "fitbitConnected"] ==
                          true
                      ? "Connected"
                      : "Not Connected",
                ),

                trailing: Icon(
                  devices[
                              "fitbitConnected"] ==
                          true
                      ? Icons.check_circle
                      : Icons.error,
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              width:
                  double.infinity,

              child:
                  ElevatedButton.icon(
                icon: const Icon(
                  Icons.watch,
                ),

                label: const Text(
                  "My Devices",
                ),

                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const MyDevicesScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
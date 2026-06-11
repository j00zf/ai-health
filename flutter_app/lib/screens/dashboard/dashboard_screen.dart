import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {

  final String token;

  const DashboardScreen({
    super.key,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dashboard",
        ),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [

            const Text(
              "Welcome to Fitbit Health",
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              "JWT Token Available",
              style: TextStyle(
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
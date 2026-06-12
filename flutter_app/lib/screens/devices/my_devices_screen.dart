import 'package:flutter/material.dart';

class MyDevicesScreen
    extends StatelessWidget {

  const MyDevicesScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Devices",
        ),
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(16),

        children: [

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.watch,
              ),

              title: const Text(
                "Fitbit",
              ),

              subtitle: const Text(
                "Not Connected",
              ),

              trailing:
                  ElevatedButton(
                onPressed: () {
                  // Fitbit setup
                },
                child: const Text(
                  "Connect",
                ),
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.watch_outlined,
              ),

              title: const Text(
                "Apple Watch",
              ),

              subtitle: const Text(
                "Coming Soon",
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.watch_outlined,
              ),

              title: const Text(
                "Google Fit",
              ),

              subtitle: const Text(
                "Coming Soon",
              ),
            ),
          ),
        ],
      ),
    );
  }
}
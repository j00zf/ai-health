import 'package:flutter/material.dart';
import '../../core/services/fitbit_service.dart';

class MyDevicesScreen extends StatefulWidget {
  const MyDevicesScreen({super.key});

  @override
  State<MyDevicesScreen> createState() => _MyDevicesScreenState();
}

class _MyDevicesScreenState extends State<MyDevicesScreen> {
  bool isFitbitConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    final connected = await FitbitService.isConnected();
    setState(() => isFitbitConnected = connected);
  }

  Future<void> _connectFitbit() async {
    final success = await FitbitService.connect(context);
    if (success) {
      setState(() => isFitbitConnected = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Fitbit Connected Successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Connection failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Devices")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.watch, color: Colors.blue, size: 32),
              title: const Text("Fitbit", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(isFitbitConnected ? "Connected ✓" : "Not Connected"),
              trailing: ElevatedButton(
                onPressed: isFitbitConnected ? null : _connectFitbit,
                child: Text(isFitbitConnected ? "Connected" : "Connect"),
              ),
            ),
          ),
          // Other devices...
        ],
      ),
    );
  }
}
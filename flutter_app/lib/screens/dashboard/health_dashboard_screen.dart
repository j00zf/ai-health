import 'package:flutter/material.dart';
import '../../core/services/health_service.dart';
import '../../core/services/auth_manager.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  Map<String, dynamic>? _healthData;
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    // Explicitly make sure we are authorized, then fetch data maps
    bool authorized = await HealthService.connect();
    if (authorized) {
      final data = await HealthService.getTodayHealthData();
      setState(() {
        _healthData = data;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Health Connect Authorization Denied")),
        );
      }
    }
  }

  Future<void> _syncToBackend() async {
    if (_healthData == null) return;
    
    setState(() => _isSyncing = true);
    
    // Retrieve your saved token from the AuthManager storage container
    String? token = await AuthManager().getToken();
    
    if (token != null) {
      bool success = await HealthService.syncToBackend(token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? "✅ Successfully synced to Pulse AI cloud!" : "❌ Cloud sync failed"),
            backgroundColor: success ? Colors.teal : Colors.redAccent,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication token missing. Please re-login.")),
        );
      }
    }
    
    setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      appBar: AppBar(
        title: const Text("Pulse AI Health", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xff9f6eff)),
            onPressed: _isLoading ? null : _fetchData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xff9f6eff)))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: const Color(0xff9f6eff),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSyncHeader(),
                    const SizedBox(height: 24),
                    
                    // Grid mapping your native metrics out to user-friendly UI component tiles
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMetricCard("Steps", "${_healthData?['steps'] ?? 0}", "steps", Icons.directions_walk_rounded, Colors.orange),
                        _buildMetricCard("Heart Rate", "${_healthData?['heartRate'] ?? 0} BPM", "Real-time", Icons.favorite_rounded, Colors.redAccent),
                        _buildMetricCard("Resting HR", "${_healthData?['restingHeartRate'] ?? 0} BPM", "Baseline", Icons.heart_broken_rounded, Colors.pink),
                        _buildMetricCard("Calories", "${_healthData?['calories'] ?? 0} kcal", "Burned", Icons.local_fire_department_rounded, Colors.red),
                        _buildMetricCard("Sleep Duration", "${_healthData?['sleepHours'] ?? 0} hrs", "Asleep", Icons.bedtime_rounded, Colors.indigo),
                        _buildMetricCard("Distance", "${_healthData?['distanceWalked'] ?? 0} m", "Delta", Icons.add_location_alt_rounded, Colors.blue),
                        _buildMetricCard("Blood Oxygen", "${_healthData?['bloodOxygen'] ?? 0}%", "SpO2", Icons.bloodtype_rounded, Colors.teal),
                        _buildMetricCard("Body Temp", "${_healthData?['bodyTemperature'] ?? 0}°C", "Core", Icons.thermostat_rounded, Colors.amber),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildMetricCard("Active Sessions", "${_healthData?['activeHours'] ?? 0} hrs", "Workout window", Icons.fitness_center_rounded, Colors.purple),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSyncHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xff29ebd4), Color(0xff9f6eff)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xff9f6eff).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Data Source Sync", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            "Provider: ${_healthData?['source'] ?? 'Health Connect'}",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isSyncing ? null : _syncToBackend,
            icon: _isSyncing 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.cloud_upload_rounded, size: 18),
            label: Text(_isSyncing ? "Syncing..." : "Push to Pulse AI Backend"),
            style: ElevatedButton.styleFrom(
              foregroundColor: const Color(0xff9f6eff),
              backgroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: accentColor.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              Text(subtitle, style: const TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff2d3748))),
              const SizedBox(height: 2),
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black.withOpacity(0.5))),
            ],
          )
        ],
      ),
    );
  }
}
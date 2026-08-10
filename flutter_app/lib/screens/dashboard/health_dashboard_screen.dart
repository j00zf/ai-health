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

  // Fallback demo data
  static const Map<String, dynamic> _demoData = {
    'steps': 7842,
    'heartRate': 72,
    'floors': 12,
    'bloodOxygen': 97.5,
    'activeZoneMinutes': 38,
    'weight': 71.4,
    'source': 'Demo Data (Google Health not connected)',
    'syncedAt': null,
  };

  @override
  void initState() {
    super.initState();
    _fetchCloudData();
  }

  Future<void> _fetchCloudData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authorized = await HealthService.connect();

      if (authorized) {
        final data = await HealthService.getTodayHealthData();

        final hasRealData = (data['steps'] ?? 0) > 0 ||
            (data['heartRate'] ?? 0) > 0 ||
            (data['floors'] ?? 0) > 0;

        if (!mounted) return;
        setState(() {
          _healthData = hasRealData
              ? data
              : {..._demoData, 'source': 'Demo Data (empty response from Google)'};
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _healthData = _demoData;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Using demo data – Google connection cancelled"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _healthData = _demoData;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error fetching data. Showing demo values."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _syncToBackend() async {
    if (_healthData == null) return;

    if (!mounted) return;
    setState(() => _isSyncing = true);

    final token = await AuthManager().getToken();

    if (token != null) {
      final success = await HealthService.syncToBackend(token);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? "✅ Cloud Data Synced Successfully!"
              : "❌ Server Sync Failed"),
          backgroundColor: success ? Colors.teal : Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No auth token found. Please login first."),
          backgroundColor: Colors.orange,
        ),
      );
    }

    if (!mounted) return;
    setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      appBar: AppBar(
        title: const Text(
          "Pulse AI Cloud",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download_rounded,
                color: Color(0xff9f6eff)),
            onPressed: _isLoading ? null : _fetchCloudData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xff9f6eff)))
          : RefreshIndicator(
              onRefresh: _fetchCloudData,
              color: const Color(0xff9f6eff),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSyncHeader(),
                    const SizedBox(height: 24),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMetricCard(
                          "Steps",
                          "${_healthData?['steps'] ?? 0}",
                          "Google Cloud",
                          Icons.directions_walk_rounded,
                          Colors.orange,
                        ),
                        _buildMetricCard(
                          "Heart Rate",
                          "${_healthData?['heartRate'] ?? 0} BPM",
                          "Wearable Stream",
                          Icons.favorite_rounded,
                          Colors.redAccent,
                        ),
                        _buildMetricCard(
                          "Floors",
                          "${_healthData?['floors'] ?? 0}",
                          "Daily Roll-up",
                          Icons.stairs_rounded,
                          Colors.purple,
                        ),
                        _buildMetricCard(
                          "SpO₂",
                          "${_healthData?['bloodOxygen'] ?? 0}%",
                          "Oxygen Saturation",
                          Icons.air_rounded,
                          Colors.teal,
                        ),
                        _buildMetricCard(
                          "Active Zone",
                          "${_healthData?['activeZoneMinutes'] ?? 0} min",
                          "Heart Zones",
                          Icons.local_fire_department_rounded,
                          Colors.deepOrange,
                        ),
                        _buildMetricCard(
                          "Weight",
                          "${_healthData?['weight'] ?? 0} kg",
                          "Latest",
                          Icons.monitor_weight_rounded,
                          Colors.blueGrey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSyncHeader() {
    final isDemo =
        (_healthData?['source'] as String? ?? '').contains('Demo');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff12c2e9), Color(0xffc471ed), Color(0xfff64f59)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Active Cloud Server Status",
            style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            _healthData?['source'] ?? 'Reconciliation Idle',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          if (isDemo) ...[
            const SizedBox(height: 6),
            const Text(
              "Showing sample data for UI testing",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isSyncing ? null : _syncToBackend,
            icon: _isSyncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        color: Colors.purple, strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined, size: 16),
            label: const Text("Push to Pulse AI Database"),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.purple,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.black26,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2d3748),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
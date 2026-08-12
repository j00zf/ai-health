import 'package:flutter/material.dart';
import '../../core/services/health_service.dart';

/// Shows every day of health data ever recorded for the signed-in user
/// (steps, heart rate, floors, SpO2, active zone minutes, weight), newest
/// day first.
class RecordHealthScreen extends StatefulWidget {
  const RecordHealthScreen({super.key});

  @override
  State<RecordHealthScreen> createState() => _RecordHealthScreenState();
}

class _RecordHealthScreenState extends State<RecordHealthScreen> {
  List<Map<String, dynamic>> _records = [];
  String _source = '';
  String? _rangeStart;
  String? _rangeEnd;
  bool _isLoading = true;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Make sure we have an active session; HealthService.connect() is a
      // no-op sign-in prompt if already connected in this run.
      final authorized =
          HealthService.isConnected ? true : await HealthService.connect();

      if (!authorized) {
        if (!mounted) return;
        setState(() {
          _records = [];
          _source = 'Google Health not connected';
          _rangeStart = null;
          _rangeEnd = null;
          _isLoading = false;
          _errorMessage = 'Connect your Google Health account to view real health records.';
        });
        return;
      }

      final history = await HealthService.getAllHealthHistory();
      final records =
          (history['records'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      if (!mounted) return;
      setState(() {
        _records = records;
        _source = history['source'] as String? ?? 'Google Health Cloud API';
        _errorMessage = records.isEmpty
            ? 'No real Google Health records were found for the selected period.'
            : null;
        _rangeStart = history['rangeStart'] as String?;
        _rangeEnd = history['rangeEnd'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _records = [];
        _source = 'Google Health Cloud API';
        _isLoading = false;
        _errorMessage = 'Could not load full history: $e';
      });
    }
  }

  String _formatDisplayDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final today = DateTime.now();
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final yesterday = today.subtract(const Duration(days: 1));
      final isYesterday = date.year == yesterday.year &&
          date.month == yesterday.month &&
          date.day == yesterday.day;

      if (isToday) return 'Today';
      if (isYesterday) return 'Yesterday';

      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return isoDate;
    }
  }

  Map<String, dynamic> get _summary {
    if (_records.isEmpty) {
      return {'avgSteps': 0, 'avgHr': 0, 'totalDays': 0};
    }
    int stepsSum = 0;
    int hrSum = 0;
    int hrCount = 0;
    for (final r in _records) {
      stepsSum += (r['steps'] as num?)?.toInt() ?? 0;
      final hr = (r['heartRate'] as num?)?.toInt() ?? 0;
      if (hr > 0) {
        hrSum += hr;
        hrCount++;
      }
    }
    return {
      'avgSteps': (stepsSum / _records.length).round(),
      'avgHr': hrCount > 0 ? (hrSum / hrCount).round() : 0,
      'totalDays': _records.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = false;
    final summary = _summary;

    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      appBar: AppBar(
        title: const Text(
          "Health Record History",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xff9f6eff)),
            onPressed: _isLoading ? null : _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xff9f6eff)))
          : RefreshIndicator(
              onRefresh: _loadHistory,
              color: const Color(0xff9f6eff),
              child: _records.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildSummaryHeader(isDemo, summary),
                        const SizedBox(height: 20),
                        if (_errorMessage != null) ...[
                          _buildInlineNotice(_errorMessage!),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          "${_records.length} day${_records.length == 1 ? '' : 's'} recorded",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._records.map(_buildDayCard),
                        const SizedBox(height: 24),
                      ],
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        const Icon(Icons.history_rounded, size: 56, color: Colors.black26),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            "No health records found yet",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            "Pull down to refresh once your device has\nsynced data to Google Health.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black38),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineNotice(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(bool isDemo, Map<String, dynamic> summary) {
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
            "All-Time Health History",
            style: TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            _source,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (_rangeStart != null && _rangeEnd != null) ...[
            const SizedBox(height: 4),
            Text(
              "$_rangeStart  →  $_rangeEnd",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          if (isDemo) ...[
            const SizedBox(height: 6),
            const Text(
              "Showing sample data for UI testing",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildSummaryStat(
                  "Avg Steps/day",
                  "${summary['avgSteps']}",
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: _buildSummaryStat(
                  "Avg Heart Rate",
                  summary['avgHr'] > 0 ? "${summary['avgHr']} BPM" : "—",
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: _buildSummaryStat(
                  "Days Tracked",
                  "${summary['totalDays']}",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildDayCard(Map<String, dynamic> record) {
    final steps = (record['steps'] as num?)?.toInt() ?? 0;
    final hr = (record['heartRate'] as num?)?.toInt() ?? 0;
    final floors = (record['floors'] as num?)?.toInt() ?? 0;
    final spo2 = (record['bloodOxygen'] as num?)?.toDouble() ?? 0.0;
    final azm = (record['activeZoneMinutes'] as num?)?.toInt() ?? 0;
    final weight = (record['weight'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDisplayDate(record['date'] as String? ?? ''),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xff2d3748),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _buildMetricChip(Icons.directions_walk_rounded, Colors.orange,
                  "$steps steps"),
              _buildMetricChip(Icons.favorite_rounded, Colors.redAccent,
                  hr > 0 ? "$hr BPM" : "— BPM"),
              _buildMetricChip(
                  Icons.stairs_rounded, Colors.purple, "$floors floors"),
              _buildMetricChip(Icons.air_rounded, Colors.teal,
                  spo2 > 0 ? "${spo2.toStringAsFixed(1)}% SpO₂" : "— SpO₂"),
              _buildMetricChip(Icons.local_fire_department_rounded,
                  Colors.deepOrange, "$azm min AZM"),
              _buildMetricChip(Icons.monitor_weight_rounded, Colors.blueGrey,
                  weight > 0 ? "${weight.toStringAsFixed(1)} kg" : "— kg"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xff4a5568),
          ),
        ),
      ],
    );
  }
}
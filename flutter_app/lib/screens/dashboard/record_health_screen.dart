import 'package:flutter/material.dart';
import '../../core/services/health_service.dart';

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
          _errorMessage =
              'Connect your Google Health account to view real health records.';
        });
        return;
      }

      final history = await HealthService.getAllHealthHistory(daysBack: 3650);
      final raw = history['records'];
      final records = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _records = records;
        _source = history['source']?.toString() ?? 'Google Health Cloud API';
        _rangeStart = history['rangeStart']?.toString();
        _rangeEnd = history['rangeEnd']?.toString();
        _isLoading = false;
        _errorMessage = records.isEmpty
            ? 'No real Google Health records were found for the available period.'
            : null;
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

  double _n(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  String _fmtDate(String value) {
    try {
      final date = DateTime.parse(value);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final today = DateTime.now();
      if (date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) {
        return 'Today';
      }
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return value;
    }
  }

  double _average(String key) {
    final values =
        _records.map((r) => _n(r[key])).where((v) => v > 0).toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      appBar: AppBar(
        title: const Text(
          'All Health History',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh all available history',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xff9f6eff)),
            onPressed: _isLoading ? null : _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xff9f6eff)),
            )
          : RefreshIndicator(
              onRefresh: _loadHistory,
              color: const Color(0xff9f6eff),
              child: _records.isEmpty
                  ? _buildEmpty()
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildSummary(),
                        const SizedBox(height: 18),
                        if (_errorMessage != null) ...[
                          _notice(_errorMessage!),
                          const SizedBox(height: 14),
                        ],
                        Text(
                          '${_records.length} recorded day${_records.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._records.map(_buildDayCard),
                        const SizedBox(height: 24),
                      ],
                    ),
            ),
    );
  }

  Widget _buildSummary() {
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
            'Complete Available Health History',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            _source,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          if (_rangeStart != null && _rangeEnd != null) ...[
            const SizedBox(height: 4),
            Text(
              '$_rangeStart  →  $_rangeEnd',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _summaryChip('Steps', '${_average("steps").round()}/day'),
              _summaryChip(
                'Heart',
                _average('heartRate') > 0
                    ? '${_average("heartRate").toStringAsFixed(1)} BPM'
                    : '—',
              ),
              _summaryChip(
                'Resting',
                _average('restingHeartRate') > 0
                    ? '${_average("restingHeartRate").toStringAsFixed(1)} BPM'
                    : '—',
              ),
              _summaryChip('Days', '${_records.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 9)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> r) {
    final metrics = <Map<String, String>>[
      {'label': 'Steps', 'value': '${_n(r["steps"]).round()}'},
      {'label': 'Distance', 'value': '${_n(r["distanceWalked"]).toStringAsFixed(2)} km'},
      {'label': 'Calories', 'value': '${_n(r["calories"]).round()} kcal'},
      {'label': 'Active', 'value': '${_n(r["activeHours"]).toStringAsFixed(1)} h'},
      {'label': 'Heart', 'value': _n(r["heartRate"]) > 0 ? '${_n(r["heartRate"]).round()} BPM' : '—'},
      {'label': 'Resting', 'value': _n(r["restingHeartRate"]) > 0 ? '${_n(r["restingHeartRate"]).round()} BPM' : '—'},
      {'label': 'Sleep', 'value': _n(r["sleepHours"]) > 0 ? '${_n(r["sleepHours"]).toStringAsFixed(1)} h' : '—'},
      {'label': 'SpO₂', 'value': _n(r["bloodOxygen"]) > 0 ? '${_n(r["bloodOxygen"]).toStringAsFixed(1)}%' : '—'},
      {'label': 'Floors', 'value': '${_n(r["floors"]).round()}'},
      {'label': 'AZM', 'value': '${_n(r["activeZoneMinutes"]).round()} min'},
      {'label': 'Weight', 'value': _n(r["weight"]) > 0 ? '${_n(r["weight"]).toStringAsFixed(1)} kg' : '—'},
      {'label': 'Temp', 'value': _n(r["bodyTemperature"]) > 0 ? '${_n(r["bodyTemperature"]).toStringAsFixed(1)} °C' : '—'},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _fmtDate(r['date']?.toString() ?? ''),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xff2d3748),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: metrics.map((m) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xfff7f7fb),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${m["label"]}: ',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: m["value"],
                        style: const TextStyle(
                          color: Color(0xff374151),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _notice(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 220),
        Icon(Icons.history_rounded, size: 58, color: Colors.black26),
        SizedBox(height: 14),
        Center(
          child: Text(
            'No health history found',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54),
          ),
        ),
      ],
    );
  }
}

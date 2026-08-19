import 'package:flutter/material.dart';
import '../../core/services/health_service.dart';

class HealthAveragesScreen extends StatefulWidget {
  final String? initialMetric;

  const HealthAveragesScreen({
    super.key,
    this.initialMetric,
  });

  @override
  State<HealthAveragesScreen> createState() => _HealthAveragesScreenState();
}

class _HealthAveragesScreenState extends State<HealthAveragesScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _records = [];
  late TabController _tabs;
  String _metric = 'steps';

  final Map<String, _MetricSpec> _metrics = {
    'steps': _MetricSpec('Steps', 'steps/day', Icons.directions_walk_rounded, 0xfff59e0b),
    'heartRate': _MetricSpec('Heart Rate', 'BPM', Icons.favorite_rounded, 0xffef4444),
    'restingHeartRate': _MetricSpec('Resting BPM', 'BPM', Icons.monitor_heart_rounded, 0xffec4899),
    'distanceWalked': _MetricSpec('Distance', 'km/day', Icons.route_rounded, 0xff3b82f6),
    'calories': _MetricSpec('Calories', 'kcal/day', Icons.local_fire_department_rounded, 0xfff97316),
    'activeHours': _MetricSpec('Active Time', 'hours/day', Icons.bolt_rounded, 0xff8b5cf6),
    'floors': _MetricSpec('Floors', 'floors/day', Icons.stairs_rounded, 0xff7c3aed),
    'sleepHours': _MetricSpec('Sleep', 'hours/day', Icons.bedtime_rounded, 0xff6366f1),
    'bloodOxygen': _MetricSpec('SpO₂', '%', Icons.air_rounded, 0xff14b8a6),
    'activeZoneMinutes': _MetricSpec('Active Zone', 'min/day', Icons.local_fire_department_rounded, 0xffea580c),
    'weight': _MetricSpec('Weight', 'kg', Icons.monitor_weight_rounded, 0xff64748b),
    'bodyTemperature': _MetricSpec('Body Temperature', '°C', Icons.thermostat_rounded, 0xffdc2626),
  };

  @override
  void initState() {
    super.initState();
    _metric = _metrics.containsKey(widget.initialMetric)
        ? widget.initialMetric!
        : 'steps';
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  double _n(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ok =
          HealthService.isConnected ? true : await HealthService.connect();
      if (!ok) {
        throw Exception('Google Health is not connected.');
      }

      final result = await HealthService.getAllHealthHistory(daysBack: 3650);
      final raw = result['records'];
      final rows = raw is List
          ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _records = rows;
        _loading = false;
        if (rows.isEmpty) {
          _error = 'No Google Health data is available.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _isoWeekKey(String dateString) {
    final d = DateTime.parse('${dateString}T12:00:00');
    final day = d.weekday;
    final thursday = d.add(Duration(days: 4 - day));
    final first = DateTime(thursday.year, 1, 1);
    final week = ((thursday.difference(first).inDays) / 7).floor() + 1;
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  Map<String, List<Map<String, dynamic>>> _groups(bool monthly) {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final row in _records) {
      final date = row['date']?.toString();
      if (date == null || date.length < 7) continue;
      final key = monthly ? date.substring(0, 7) : _isoWeekKey(date);
      result.putIfAbsent(key, () => []).add(row);
    }
    return result;
  }

  double _average(List<Map<String, dynamic>> rows, String key) {
    final values = rows.map((r) => _n(r[key])).where((v) => v > 0).toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _allTime() => _average(_records, _metric);

  String _format(double value) {
    if (_metric == 'steps' ||
        _metric == 'floors' ||
        _metric == 'activeZoneMinutes') {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final spec = _metrics[_metric]!;

    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      appBar: AppBar(
        title: const Text(
          'Health Averages',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xff9f6eff)),
            onPressed: _loading ? null : _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: const Color(0xff6c5ce7),
          unselectedLabelColor: Colors.black38,
          indicatorColor: const Color(0xff6c5ce7),
          tabs: const [
            Tab(text: 'All Time'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xff9f6eff)),
            )
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    _buildMetricSelector(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _buildAllTime(spec),
                          _buildGrouped(_groups(false), spec, false),
                          _buildGrouped(_groups(true), spec, true),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMetricSelector() {
    return Container(
      height: 68,
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: _metrics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final key = _metrics.keys.elementAt(index);
          final spec = _metrics[key]!;
          final selected = key == _metric;
          return ChoiceChip(
            selected: selected,
            label: Text(spec.title),
            avatar: Icon(spec.icon, size: 16),
            selectedColor: Color(spec.color).withOpacity(.16),
            labelStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? Color(spec.color) : Colors.black54,
            ),
            onSelected: (_) => setState(() => _metric = key),
          );
        },
      ),
    );
  }

  Widget _buildAllTime(_MetricSpec spec) {
    final value = _allTime();
    final validDays =
        _records.where((r) => _n(r[_metric]) > 0).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _hero(spec, value, validDays),
        const SizedBox(height: 16),
        _buildInsightCard(
          'How this is calculated',
          'The average uses every available recorded day from the earliest '
              'Google Health entry returned by the API through the latest entry. '
              'Missing metric values are excluded instead of being treated as zero.',
          Icons.calculate_rounded,
        ),
        const SizedBox(height: 16),
        _buildMetricOverview(),
      ],
    );
  }

  Widget _buildGrouped(
    Map<String, List<Map<String, dynamic>>> groups,
    _MetricSpec spec,
    bool monthly,
  ) {
    final entries = groups.entries.toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildChart(entries, spec),
        const SizedBox(height: 16),
        Text(
          monthly ? 'Monthly averages' : 'Weekly averages',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...entries.map((entry) {
          final avg = _average(entry.value, _metric);
          final valid = entry.value.where((r) => _n(r[_metric]) > 0).length;
          return Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Color(spec.color).withOpacity(.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(spec.icon, color: Color(spec.color)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '$valid days with ${spec.title.toLowerCase()} data',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  avg > 0 ? _format(avg) : '—',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  spec.unit,
                  style: const TextStyle(fontSize: 9, color: Colors.black38),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildChart(
    List<MapEntry<String, List<Map<String, dynamic>>>> entries,
    _MetricSpec spec,
  ) {
    final visible = entries.take(12).toList().reversed.toList();
    final values = visible.map((e) => _average(e.value, _metric)).toList();
    final maxValue =
        values.fold<double>(0, (max, value) => value > max ? value : max);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend — ${spec.title}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(visible.length, (index) {
                final value = values[index];
                final fraction = maxValue <= 0 ? 0.0 : value / maxValue;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (value > 0)
                          Text(
                            _format(value),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          height: 120 * fraction,
                          decoration: BoxDecoration(
                            color: Color(spec.color),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          visible[index].key.length > 7
                              ? visible[index].key.substring(5)
                              : visible[index].key,
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(_MetricSpec spec, double value, int validDays) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff6c5ce7), Color(0xff9f6eff)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(spec.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All-time average',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  value > 0 ? _format(value) : '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${spec.title} • ${spec.unit} • $validDays valid days',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricOverview() {
    final specs = _metrics.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All Metrics — All-Time',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...specs.map((entry) {
          final avg = _average(_records, entry.key);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: Icon(entry.value.icon, color: Color(entry.value.color)),
            title: Text(
              entry.value.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            trailing: Text(
              avg > 0 ? '${_formatMetric(entry.key, avg)} ${entry.value.unit}' : '—',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          );
        }),
      ],
    );
  }

  String _formatMetric(String key, double value) {
    if (key == 'steps' || key == 'floors' || key == 'activeZoneMinutes') {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  Widget _buildInsightCard(String title, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff6c5ce7)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.health_and_safety_outlined,
                size: 56, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unable to load health averages.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricSpec {
  final String title;
  final String unit;
  final IconData icon;
  final int color;

  const _MetricSpec(this.title, this.unit, this.icon, this.color);
}

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/services/ml_health_service.dart';
import 'ml_health_details_screen.dart';
import 'ml_health_history_screen.dart';

class MlHealthDashboardScreen extends StatefulWidget {
  final String token;

  const MlHealthDashboardScreen({
    super.key,
    required this.token,
  });

  @override
  State<MlHealthDashboardScreen> createState() =>
      _MlHealthDashboardScreenState();
}

class _MlHealthDashboardScreenState
    extends State<MlHealthDashboardScreen> {
  bool isLoading = true;

  String? errorMessage;

  Map<String, dynamic>? analysis;

  @override
  void initState() {
    super.initState();

    _loadAnalysis();
  }

  // ============================================================
  // LOAD LATEST ANALYSIS
  // ============================================================

  Future<void> _loadAnalysis() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result =
        await MlHealthService.getLatestAnalysis(
      token: widget.token,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final rawData = result['data'];

      setState(() {
        analysis = rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : null;

        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
        errorMessage =
            result['message']?.toString() ??
            'Failed to load ML health analysis';
      });
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _number(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  String _text(dynamic value) {
    if (value == null) return '—';

    final text = value.toString();

    return text.isEmpty ? '—' : text;
  }

  String _scoreText(dynamic value) {
    return _number(value).toStringAsFixed(1);
  }

  Color _scoreColor(double score) {
    if (score >= 85) {
      return Colors.green;
    }

    if (score >= 65) {
      return Colors.orange;
    }

    return Colors.red;
  }

  String _statusText(double score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Moderate';

    return 'Needs Attention';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ML Health Analysis',
        ),
        actions: [
          IconButton(
            icon: const Icon(Symbols.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MlHealthHistoryScreen(
                    token: widget.token,
                  ),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Symbols.refresh),
            onPressed: _loadAnalysis,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalysis,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return ListView(
        children: [
          const SizedBox(height: 150),

          Icon(
            Symbols.error,
            size: 64,
            color: Colors.red.shade400,
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: FilledButton(
              onPressed: _loadAnalysis,
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (analysis == null) {
      return ListView(
        children: const [
          SizedBox(height: 180),

          Icon(
            Symbols.health_and_safety,
            size: 70,
          ),

          SizedBox(height: 20),

          Center(
            child: Text(
              'No ML health analysis available yet',
            ),
          ),
        ],
      );
    }

    final scores =
        _map(analysis!['scores']);

    final wellness =
        _map(analysis!['wellness']);

    final forecast =
        _map(analysis!['forecast']);

    final dataQuality =
        _map(analysis!['dataQuality']);

    final overallScore =
        _number(scores['overallWellbeingScore']);

    final heartScore =
        _number(scores['heartHealthScore']);

    final healthScore =
        _number(scores['healthScore']);

    final personalScore =
        _number(scores['personalWellnessScore']);

    final latestRecord =
        _map(analysis!['latestHealthRecord']);

    final missingFields =
        analysis!['missingFields'] is List
            ? List<dynamic>.from(
                analysis!['missingFields'],
              )
            : <dynamic>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ======================================================
        // OVERALL SCORE
        // ======================================================

        _buildOverallScoreCard(
          overallScore,
        ),

        const SizedBox(height: 16),

        // ======================================================
        // SCORE CARDS
        // ======================================================

        Row(
          children: [
            Expanded(
              child: _buildMiniScoreCard(
                title: 'Heart',
                score: heartScore,
                icon: Symbols.favorite,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildMiniScoreCard(
                title: 'Health',
                score: healthScore,
                icon: Symbols.health_and_safety,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildMiniScoreCard(
                title: 'Personal',
                score: personalScore,
                icon: Symbols.person,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildMiniScoreCard(
                title: 'Baseline',
                score: _number(
                  scores['wellnessBaselineScore'],
                ),
                icon: Symbols.analytics,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ======================================================
        // LATEST HEALTH RECORD
        // ======================================================

        const Text(
          'Latest Health Record',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        _buildLatestRecordCard(
          latestRecord,
        ),

        // ======================================================
        // MISSING DATA
        // ======================================================

        if (missingFields.isNotEmpty) ...[
          const SizedBox(height: 16),

          _buildMissingDataCard(
            missingFields,
          ),
        ],

        const SizedBox(height: 24),

        // ======================================================
        // WELLNESS
        // ======================================================

        const Text(
          'Personal Wellness',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        _buildWellnessCard(
          wellness,
        ),

        const SizedBox(height: 24),

        // ======================================================
        // FORECAST
        // ======================================================

        if (forecast.isNotEmpty) ...[
          const Text(
            'Wellbeing Forecast',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _buildForecastCard(
            forecast,
          ),
        ],

        const SizedBox(height: 24),

        // ======================================================
        // DATA QUALITY
        // ======================================================

        _buildDataQualityCard(
          dataQuality,
        ),

        const SizedBox(height: 20),

        // ======================================================
        // DETAILS BUTTON
        // ======================================================

        FilledButton.icon(
          icon: const Icon(
            Symbols.analytics,
          ),
          label: const Text(
            'View Full Analysis',
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MlHealthDetailsScreen(
                  analysis: analysis!,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        OutlinedButton.icon(
          icon: const Icon(
            Symbols.trending_up,
          ),
          label: const Text(
            'View Improvement History',
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MlHealthHistoryScreen(
                  token: widget.token,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  // ============================================================
  // OVERALL SCORE
  // ============================================================

  Widget _buildOverallScoreCard(
    double score,
  ) {
    final color =
        _scoreColor(score);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Current Wellbeing Score',
              style: TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              _scoreText(score),
              style: TextStyle(
                fontSize: 58,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            Text(
              _statusText(score),
              style: TextStyle(
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MINI SCORE CARD
  // ============================================================

  Widget _buildMiniScoreCard({
    required String title,
    required double score,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon),

            const SizedBox(height: 10),

            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _scoreText(score),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LATEST RECORD
  // ============================================================

  Widget _buildLatestRecordCard(
    Map<String, dynamic> record,
  ) {
    if (record.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No latest health record available.',
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _recordRow(
              'Date',
              _text(record['date']),
            ),

            _recordRow(
              'Steps',
              _text(record['steps']),
            ),

            _recordRow(
              'Sleep',
              '${_text(record['sleep'])} hrs',
            ),

            _recordRow(
              'Heart Rate',
              '${_text(record['heartRate'])} bpm',
            ),

            _recordRow(
              'Resting Heart Rate',
              '${_text(record['restingHeartRate'])} bpm',
            ),

            _recordRow(
              'Oxygen Saturation',
              '${_text(record['oxygenSaturation'])}%',
            ),

            _recordRow(
              'Weight',
              '${_text(record['weight'])} kg',
            ),

            _recordRow(
              'BMI',
              _text(record['bmi']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MISSING DATA
  // ============================================================

  Widget _buildMissingDataCard(
    List<dynamic> missingFields,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Symbols.info,
                ),

                SizedBox(width: 8),

                Text(
                  'Estimated Data Used',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Text(
              'Some health values were missing and were replaced using your available historical averages.',
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: missingFields
                  .map(
                    (field) => Chip(
                      label: Text(
                        field.toString(),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WELLNESS
  // ============================================================

  Widget _buildWellnessCard(
    Map<String, dynamic> wellness,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _recordRow(
              'Status',
              _text(wellness['status']),
            ),

            _recordRow(
              'Baseline',
              _scoreText(
                wellness['baselineScore'],
              ),
            ),

            _recordRow(
              'Longitudinal',
              _scoreText(
                wellness['longitudinalScore'],
              ),
            ),

            _recordRow(
              'Personal Wellness',
              _scoreText(
                wellness[
                    'personalWellnessScore'],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FORECAST
  // ============================================================

  Widget _buildForecastCard(
    Map<String, dynamic> forecast,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _recordRow(
              '7 Days',
              _scoreText(
                forecast['forecast7d'],
              ),
            ),

            _recordRow(
              '14 Days',
              _scoreText(
                forecast['forecast14d'],
              ),
            ),

            _recordRow(
              '30 Days',
              _scoreText(
                forecast['forecast30d'],
              ),
            ),

            _recordRow(
              'Trajectory',
              _text(
                forecast['trajectory'],
              ).replaceAll('_', ' '),
            ),

            _recordRow(
              'Confidence',
              '${_scoreText(forecast['confidence'])}%',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATA QUALITY
  // ============================================================

  Widget _buildDataQualityCard(
    Map<String, dynamic> quality,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(
                  Symbols.verified,
                ),

                SizedBox(width: 8),

                Text(
                  'Data Quality',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _recordRow(
              'Records',
              _text(
                quality['recordsAnalyzed'],
              ),
            ),

            _recordRow(
              'Completeness',
              '${_scoreText(quality['completeness'])}%',
            ),

            _recordRow(
              'Confidence',
              '${_scoreText(quality['confidence'])}%',
            ),

            _recordRow(
              'Quality',
              _text(
                quality['qualityLevel'],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
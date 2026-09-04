import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/services/ml_health_service.dart';

class MlHealthHistoryScreen
    extends StatefulWidget {
  final String token;

  const MlHealthHistoryScreen({
    super.key,
    required this.token,
  });

  @override
  State<MlHealthHistoryScreen>
      createState() =>
          _MlHealthHistoryScreenState();
}

class _MlHealthHistoryScreenState
    extends State<MlHealthHistoryScreen> {
  bool isLoading = true;

  String? errorMessage;

  int selectedDays = 30;

  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();

    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result =
        await MlHealthService.getHistory(
      token: widget.token,
      days: selectedDays,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final rawData = result['data'];

      final List<Map<String, dynamic>>
          loadedHistory = [];

      if (rawData is List) {
        for (final item in rawData) {
          if (item is Map) {
            loadedHistory.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      setState(() {
        history = loadedHistory;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;

        errorMessage =
            result['message']?.toString() ??
            'Failed to load history';
      });
    }
  }

  double _number(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  Map<String, dynamic> _map(
    dynamic value,
  ) {
    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return {};
  }

  // ============================================================
  // IMPROVEMENT
  // ============================================================

  double get _latestScore {
    if (history.isEmpty) return 0;

    final latest =
        history.first;

    final scores =
        _map(latest['scores']);

    return _number(
      scores['overallWellbeingScore'],
    );
  }

  double get _oldestScore {
    if (history.isEmpty) return 0;

    final oldest =
        history.last;

    final scores =
        _map(oldest['scores']);

    return _number(
      scores['overallWellbeingScore'],
    );
  }

  double get _improvement {
    return _latestScore -
        _oldestScore;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ML Health History',
        ),
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadHistory,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(
            value: 7,
            label: Text('7 Days'),
          ),

          ButtonSegment(
            value: 30,
            label: Text('30 Days'),
          ),

          ButtonSegment(
            value: 90,
            label: Text('90 Days'),
          ),
        ],
        selected: {
          selectedDays,
        },
        onSelectionChanged: (
          Set<int> values,
        ) {
          setState(() {
            selectedDays =
                values.first;
          });

          _loadHistory();
        },
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

          Center(
            child: Text(
              errorMessage!,
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: FilledButton(
              onPressed: _loadHistory,
              child: const Text(
                'Retry',
              ),
            ),
          ),
        ],
      );
    }

    if (history.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 160),

          Icon(
            Symbols.history,
            size: 70,
          ),

          SizedBox(height: 16),

          Center(
            child: Text(
              'No Wellness analysis history available',
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildImprovementCard(),

        const SizedBox(height: 24),

        const Text(
          'Analysis History',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        ...history.map(
          _buildHistoryCard,
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  // ============================================================
  // IMPROVEMENT CARD
  // ============================================================

  Widget _buildImprovementCard() {
    final improvement =
        _improvement;

    final isPositive =
        improvement >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isPositive
                  ? Symbols.trending_up
                  : Symbols.trending_down,
              size: 40,
              color: isPositive
                  ? Colors.green
                  : Colors.red,
            ),

            const SizedBox(height: 12),

            const Text(
              'Overall Improvement',
              style: TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${improvement >= 0 ? '+' : ''}${improvement.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 36,
                fontWeight:
                    FontWeight.bold,
                color: isPositive
                    ? Colors.green
                    : Colors.red,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'From ${_oldestScore.toStringAsFixed(1)} to ${_latestScore.toStringAsFixed(1)}',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HISTORY CARD
  // ============================================================

  Widget _buildHistoryCard(
    Map<String, dynamic> item,
  ) {
    final scores =
        _map(item['scores']);

    final overall =
        _number(
      scores['overallWellbeingScore'],
    );

    final personal =
        _number(
      scores['personalWellnessScore'],
    );

    final createdAt =
        item['createdAt']?.toString() ??
            item['date']?.toString() ??
            'Unknown date';

    final quality =
        _map(item['dataQuality']);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            overall
                .toStringAsFixed(0),
          ),
        ),
        title: Text(
          'Overall: ${overall.toStringAsFixed(1)}',
        ),
        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),

            Text(
              'Personal wellness: ${personal.toStringAsFixed(1)}',
            ),

            Text(
              'Records: ${quality['recordsAnalyzed'] ?? '—'}',
            ),

            Text(
              createdAt,
            ),
          ],
        ),
      ),
    );
  }
}
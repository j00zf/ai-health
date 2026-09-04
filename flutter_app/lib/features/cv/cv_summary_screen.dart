import 'package:flutter/material.dart';

import '../../core/services/cv_service.dart';

class CVSummaryScreen
    extends StatefulWidget {

  const CVSummaryScreen({
    super.key,
  });

  @override
  State<CVSummaryScreen>
      createState() =>
          _CVSummaryScreenState();
}

class _CVSummaryScreenState
    extends State<CVSummaryScreen> {

  final CVService _service =
      CVService();

  bool _loading = true;

  Map<String, dynamic>? _summary;

  List<dynamic> _trends = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final summary =
          await _service.getSummary();

      final trends =
          await _service.getTrends(
        limit: 30,
      );

      if (!mounted) return;

      setState(() {
        _summary =
            summary['summary']
                as Map<String, dynamic>?;

        _trends =
            trends['trends']
                as List<dynamic>? ??
                [];

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  double _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xfff5f7fb),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'CV Trends',
          style: TextStyle(
            color: Color(0xff1f2937),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _load,

              child: ListView(
                padding:
                    const EdgeInsets.all(16),

                children: [
                  _buildOverview(),

                  const SizedBox(
                    height: 18,
                  ),

                  _buildTrendSection(),

                  const SizedBox(
                    height: 18,
                  ),

                  _buildExplanation(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverview() {
    final summary =
        _summary ?? {};

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        const Text(
          'Your Visual Trends',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _summaryCard(
                'Avg. stress signal',
                _percent(summary['averageStress']),
                Icons.psychology_alt_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                'Model confidence',
                _percent(summary['averageStressConfidence']),
                Icons.verified_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _summaryCard(
                'Avg. fatigue',
                _percent(
                  summary[
                      'averageFatigue'],
                ),
                Icons.bedtime,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _summaryCard(
                'Alertness',
                _percent(
                  summary[
                      'averageAlertness'],
                ),
                Icons.visibility,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _summaryCard(
                'Eye closure',
                _percent(
                  summary[
                      'averageEyeClosure'],
                ),
                Icons.remove_red_eye,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _summaryCard(
                'Skin sheen',
                _percent(
                  summary[
                      'averageSkinSheen'],
                ),
                Icons.auto_awesome,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            icon,
            color:
                const Color(0xff6c5ce7),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendSection() {
    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Recent Measurements',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(height: 16),

          if (_trends.isEmpty)
            const Text(
              'Not enough data for trends.',
              style: TextStyle(
                color: Colors.black54,
              ),
            )
          else
            ..._trends
                .reversed
                .take(10)
                .map(
                  (item) =>
                      _trendItem(
                    item
                        as Map<String,
                            dynamic>,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _trendItem(
    Map<String, dynamic> item,
  ) {
    final stress =
        _number(
      item['stress'],
    );

    final fatigue =
        _number(
      item['fatigue'],
    );

    final alertness =
        _number(
      item['alertness'],
    );

    final date =
        item['capturedAt']
            ?.toString() ??
        '';

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),

      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatDate(date),
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),

              Text(
                'S ${(stress * 100).round()}%',
              ),

              const SizedBox(width: 12),

              Text(
                'F ${(fatigue * 100).round()}%',
              ),

              const SizedBox(width: 12),

              Text(
                'A ${(alertness * 100).round()}%',
              ),
            ],
          ),

          const SizedBox(height: 7),

          LinearProgressIndicator(
            value: fatigue.clamp(
              0,
              1,
            ),

            minHeight: 7,

            borderRadius:
                BorderRadius.circular(
              10,
            ),

            backgroundColor:
                Colors.grey.shade200,

            valueColor:
                const AlwaysStoppedAnimation(
              Color(0xff6c5ce7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanation() {
    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(
          0xff6c5ce7,
        ).withOpacity(.07),

        borderRadius:
            BorderRadius.circular(18),
      ),

      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color:
                    Color(0xff6c5ce7),
              ),

              SizedBox(width: 8),

              Text(
                'About Stress trends',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),

          SizedBox(height: 9),

          Text(
            'These trends describe changes in visual features detected by the computer-vision system. They are not medical diagnoses.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  String _percent(dynamic value) {
    if (value == null) {
      return '--';
    }

    return '${(_number(value) * 100).round()}%';
  }

  String _formatDate(
    String value,
  ) {
    try {
      final date =
          DateTime.parse(value);

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }
}
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class MlHealthDetailsScreen
    extends StatelessWidget {
  final Map<String, dynamic> analysis;

  const MlHealthDetailsScreen({
    super.key,
    required this.analysis,
  });

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

  List<dynamic> _list(
    dynamic value,
  ) {
    if (value is List) {
      return List<dynamic>.from(value);
    }

    return [];
  }

  String _text(dynamic value) {
    if (value == null) return '—';

    return value.toString();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final explanation =
        _map(analysis['explanation']);

    final recommendations =
        _map(analysis['recommendations']);

    final aiInterpretation =
        _map(analysis['aiInterpretation']);

    final wellness =
        _map(analysis['wellness']);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Full Wellness Analysis',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ====================================================
          // EXPLANATION
          // ====================================================

          _sectionTitle(
            'Wellness Explanation',
          ),

          _cardText(
            explanation[
                    'trendExplanation'] ??
                explanation['trend'],
          ),

          const SizedBox(height: 20),

          // ====================================================
          // SIGNALS
          // ====================================================

          _sectionTitle(
            'Wellness Signals',
          ),

          _buildSignals(
            _list(wellness['signals']),
          ),

          const SizedBox(height: 20),

          // ====================================================
          // RECOMMENDATIONS
          // ====================================================

          _sectionTitle(
            'Recommendations',
          ),

          _buildRecommendations(
            recommendations,
          ),

          const SizedBox(height: 20),

          // ====================================================
          // AI INTERPRETATION
          // ====================================================

          _sectionTitle(
            'AI Wellbeing Interpretation',
          ),

          _buildAiInterpretation(
            aiInterpretation,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget _cardText(
    dynamic text,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _text(text),
        ),
      ),
    );
  }

  Widget _buildSignals(
    List<dynamic> signals,
  ) {
    if (signals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No significant wellness signals identified.',
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: signals.map(
          (signal) {
            final data = _map(signal);

            return ListTile(
              leading: const Icon(
                Symbols.trending_up,
              ),
              title: Text(
                _text(
                  data['dimension'] ??
                      data['area'],
                ),
              ),
              subtitle: Text(
                _text(
                  data['direction'] ??
                      data['trend'],
                ),
              ),
              trailing: Text(
                _text(
                  data['strength'],
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _buildRecommendations(
    Map<String, dynamic> recommendations,
  ) {
    final items = _list(
      recommendations['recommendations'],
    );

    final mainOpportunity =
        _map(
      recommendations['mainOpportunity'],
    );

    final maintenance =
        _list(
      recommendations['maintenance'],
    );

    return Column(
      children: [
        if (mainOpportunity.isNotEmpty)
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Main Opportunity',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _text(
                      mainOpportunity['area'],
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Reason: ${_text(mainOpportunity['reason'])}',
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Action: ${_text(mainOpportunity['action'])}',
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Goal: ${_text(mainOpportunity['goal'])}',
                  ),
                ],
              ),
            ),
          ),

        if (items.isNotEmpty) ...[
          const SizedBox(height: 12),

          ...items.map(
            (item) {
              final data = _map(item);

              return Card(
                child: ListTile(
                  title: Text(
                    _text(
                      data['area'],
                    ),
                  ),
                  subtitle: Text(
                    _text(
                      data['action'],
                    ),
                  ),
                ),
              );
            },
          ),
        ],

        if (maintenance.isNotEmpty) ...[
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Maintain',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ...maintenance.map(
                    (item) => Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Symbols.check_circle,
                            size: 18,
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          Text(
                            _text(item),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAiInterpretation(
    Map<String, dynamic> interpretation,
  ) {
    if (interpretation.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'AI interpretation is not available.',
          ),
        ),
      );
    }

    return Column(
      children: [
        if (interpretation['summary'] != null)
          _cardText(
            interpretation['summary'],
          ),

        if (interpretation['narrative'] != null) ...[
          const SizedBox(height: 12),

          _cardText(
            interpretation['narrative'],
          ),
        ],

        if (interpretation['forecastInterpretation'] !=
            null) ...[
          const SizedBox(height: 12),

          _cardText(
            interpretation[
                'forecastInterpretation'],
          ),
        ],
      ],
    );
  }
}
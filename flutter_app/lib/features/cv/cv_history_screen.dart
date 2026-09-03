import 'package:flutter/material.dart';

import '../../core/services/cv_service.dart';
import 'cv_analysis_detail_screen.dart';

class CVHistoryScreen
    extends StatefulWidget {

  const CVHistoryScreen({
    super.key,
  });

  @override
  State<CVHistoryScreen>
      createState() =>
          _CVHistoryScreenState();
}

class _CVHistoryScreenState
    extends State<CVHistoryScreen> {

  final CVService _service =
      CVService();

  bool _loading = true;

  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response =
          await _service.getHistory(
        limit: 100,
      );

      if (!mounted) return;

      setState(() {
        _items =
            response['analyses']
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
          'CV History',
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

              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(
                          height: 180,
                        ),

                        Center(
                          child: Text(
                            'No CV analyses yet.',
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),

                      itemCount:
                          _items.length,

                      itemBuilder:
                          (context, index) {
                        final item =
                            _items[index]
                                as Map<String,
                                    dynamic>;

                        return _buildItem(
                          item,
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildItem(
    Map<String, dynamic> item,
  ) {
    final signals =
        item['derivedSignals']
            as Map<String, dynamic>?;

    final stress =
        item['stressAnalysis']
            as Map<String, dynamic>?;

    final stressScore = _number(
      stress?['stressScore'] ?? signals?['stressScore'],
    );

    final fatigue =
        _number(
      signals?[
          'visualFatigueScore'],
    );

    final alertness =
        _number(
      signals?[
          'alertnessScore'],
    );

    final captured =
        item['capturedAt']
            ?.toString() ??
        '';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),

        leading: Container(
          width: 48,
          height: 48,

          decoration: BoxDecoration(
            color: const Color(
              0xff6c5ce7,
            ).withOpacity(.1),

            borderRadius:
                BorderRadius.circular(14),
          ),

          child: const Icon(
            Icons.face,
            color:
                Color(0xff6c5ce7),
          ),
        ),

        title: Text(
          _formatDate(captured),
          style: const TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),

        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 6,
          ),

          child: Text(
            'Stress ${(stressScore * 100).round()}%  •  '
            'Fatigue ${(fatigue * 100).round()}%  •  '
            'Alertness ${(alertness * 100).round()}%',
          ),
        ),

        trailing:
            const Icon(
          Icons.chevron_right,
        ),

        onTap: () {
          final id =
              item['_id']?.toString();

          if (id == null) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CVAnalysisDetailScreen(
                analysisId: id,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(
    String value,
  ) {
    try {
      final date =
          DateTime.parse(value);

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }
}
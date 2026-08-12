import 'package:flutter/material.dart';

import '../../core/services/cv_service.dart';
import 'cv_camera_screen.dart';
import 'cv_history_screen.dart';
import 'cv_summary_screen.dart';
import 'cv_analysis_detail_screen.dart';

class CVAnalysisScreen extends StatefulWidget {
  const CVAnalysisScreen({
    super.key,
  });

  @override
  State<CVAnalysisScreen> createState() =>
      _CVAnalysisScreenState();
}

class _CVAnalysisScreenState
    extends State<CVAnalysisScreen> {

  final CVService _cvService = CVService();

  bool _loading = true;

  Map<String, dynamic>? _latest;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  Future<void> _loadLatest() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response =
          await _cvService.getLatest();

      if (!mounted) return;

      setState(() {
        _latest =
            response['analysis']
                as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _latest = null;
        _error = e.toString();
      });
    }
  }

  double _number(
    dynamic value,
  ) {
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
        elevation: 0,
        backgroundColor: Colors.white,

        title: const Row(
          children: [
            Icon(
              Icons.face_retouching_natural,
              color: Color(0xff6c5ce7),
            ),
            SizedBox(width: 10),
            Text(
              'CV Analysis',
              style: TextStyle(
                color: Color(0xff1f2937),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _loadLatest,

        child: ListView(
          padding:
              const EdgeInsets.all(16),

          children: [
            _buildHeaderCard(),

            const SizedBox(height: 18),

            if (_loading)
              const Center(
                child: Padding(
                  padding:
                      EdgeInsets.all(40),
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else if (_latest != null)
              _buildLatestAnalysis()
            else
              _buildEmptyState(),

            const SizedBox(height: 18),

            _buildActionGrid(),

            const SizedBox(height: 18),

            _buildSafetyCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff6c5ce7),
            Color(0xff8e7dff),
          ],
        ),

        borderRadius:
            BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: const Color(
              0xff6c5ce7,
            ).withOpacity(.22),
            blurRadius: 20,
            offset:
                const Offset(0, 10),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.visibility_rounded,
            color: Colors.white,
            size: 36,
          ),

          const SizedBox(height: 14),

          const Text(
            'Computer Vision Health Signals',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Analyze facial features and visual signals over time.',
            style: TextStyle(
              color: Colors.white
                  .withOpacity(.85),
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const CVCameraScreen(),
                  ),
                );

                _loadLatest();
              },

              icon: const Icon(
                Icons.camera_alt_rounded,
              ),

              label: const Text(
                'Analyze My Face',
              ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.white,
                foregroundColor:
                    const Color(
                      0xff6c5ce7,
                    ),
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestAnalysis() {
    final data = _latest!;

    final quality =
        data['imageQuality']
            as Map<String, dynamic>?;

    final signals =
        data['derivedSignals']
            as Map<String, dynamic>?;

    final eyes =
        data['eyeSignals']
            as Map<String, dynamic>?;

    final fatigue =
        _number(
      signals?['visualFatigueScore'],
    );

    final alertness =
        _number(
      signals?['alertnessScore'],
    );

    final eyeClosure =
        _number(
      signals?['eyeClosureScore'],
    );

    final blinkCount =
        _number(
      eyes?['blinkCount'],
    );

    final faceConfidence =
        _number(
      quality?['faceConfidence'],
    );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        const Text(
          'Latest Analysis',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xff1f2937),
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding:
              const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: Colors.black
                  .withOpacity(.05),
            ),
          ),

          child: Column(
            children: [
              Row(
                children: [
                  _metric(
                    'Face',
                    '${(faceConfidence * 100).round()}%',
                    Icons.face,
                  ),

                  _metric(
                    'Fatigue',
                    '${(fatigue * 100).round()}%',
                    Icons.bedtime_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  _metric(
                    'Alertness',
                    '${(alertness * 100).round()}%',
                    Icons.visibility,
                  ),

                  _metric(
                    'Eye closure',
                    '${(eyeClosure * 100).round()}%',
                    Icons.remove_red_eye_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  _metric(
                    'Blinks',
                    blinkCount
                        .round()
                        .toString(),
                    Icons.remove_red_eye,
                  ),

                  const Spacer(),
                ],
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,

                child: OutlinedButton(
                  onPressed: () {
                    final id =
                        data['_id']
                            ?.toString();

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

                  child: const Text(
                    'View Full Analysis',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metric(
    String title,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,

            decoration: BoxDecoration(
              color: const Color(
                0xff6c5ce7,
              ).withOpacity(.1),
              borderRadius:
                  BorderRadius.circular(12),
            ),

            child: Icon(
              icon,
              color:
                  const Color(0xff6c5ce7),
              size: 20,
            ),
          ),

          const SizedBox(width: 9),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                ),
              ),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding:
          const EdgeInsets.all(28),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Column(
        children: [
          const Icon(
            Icons.face_retouching_natural,
            size: 55,
            color: Color(0xff6c5ce7),
          ),

          const SizedBox(height: 12),

          const Text(
            'No CV analysis yet',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Take your first facial analysis to start building your visual health history.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            icon:
                Icons.history_rounded,
            title: 'History',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const CVHistoryScreen(),
                ),
              );
            },
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _actionCard(
            icon:
                Icons.insights_rounded,
            title: 'Trends',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const CVSummaryScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(18),

      child: Container(
        padding:
            const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
        ),

        child: Column(
          children: [
            Icon(
              icon,
              color:
                  const Color(0xff6c5ce7),
              size: 30,
            ),

            const SizedBox(height: 8),

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyCard() {
    return Container(
      padding:
          const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.orange
            .withOpacity(.08),
        borderRadius:
            BorderRadius.circular(16),
      ),

      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'CV signals are visual indicators only. They do not diagnose medical conditions or confirm fatigue, sweating, or other health conditions.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
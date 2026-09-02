import 'package:flutter/material.dart';

import '../../core/services/cv_service.dart';

class CVAnalysisDetailScreen
    extends StatefulWidget {

  final String analysisId;

  const CVAnalysisDetailScreen({
    super.key,
    required this.analysisId,
  });

  @override
  State<CVAnalysisDetailScreen>
      createState() =>
          _CVAnalysisDetailScreenState();
}

class _CVAnalysisDetailScreenState
    extends State<CVAnalysisDetailScreen> {

  final CVService _service =
      CVService();

  bool _loading = true;

  Map<String, dynamic>? _analysis;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response =
          await _service.getById(
        widget.analysisId,
      );

      if (!mounted) return;

      setState(() {
        _analysis =
            response['analysis']
                as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
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
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'CV Analysis Details',
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
          : _analysis == null
              ? const Center(
                  child: Text(
                    'Analysis not found',
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final data = _analysis!;

    final quality =
        data['imageQuality']
            as Map<String, dynamic>?;

    final geometry =
        data['geometry']
            as Map<String, dynamic>?;

    final eyes =
        data['eyeSignals']
            as Map<String, dynamic>?;

    final pose =
        data['headPose']
            as Map<String, dynamic>?;

    final signals =
        data['derivedSignals']
            as Map<String, dynamic>?;

    final stress =
        data['stressAnalysis']
            as Map<String, dynamic>?;

    final skin =
        data['skinAppearance']
            as Map<String, dynamic>?;

    final capture =
        data['captureMetadata']
            as Map<String, dynamic>?;

    return ListView(
      padding:
          const EdgeInsets.all(16),

      children: [
        _section(
          title: 'Facial Stress Model',
          icon: Icons.psychology_alt_rounded,
          children: [
            _row(
              stress?['labelMappingVerified'] == true ? 'Stress signal' : 'Class 1 signal',
              _percent(stress?['stressScore'] ?? signals?['stressScore']),
            ),
            _row('Model confidence', _percent(stress?['confidence'] ?? signals?['stressConfidence'])),
            _row('Predicted class', stress?['predictedClassName']?.toString() ?? 'Unavailable'),
            _row('Signal level', stress?['stressLevel']?.toString() ?? 'Unavailable'),
            _row('Class 0 probability', _percent(stress?['class0Probability'])),
            _row('Class 1 probability', _percent(stress?['class1Probability'])),
            _row(
              'Label mapping',
              stress?['labelMappingVerified'] == true ? 'Verified' : 'Not yet verified',
            ),
          ],
        ),

        const SizedBox(height: 12),

        _section(
          title: 'Visual Signals',
          icon: Icons.insights_rounded,
          children: [
            _row(
              'Visual fatigue',
              _percent(
                signals?[
                    'visualFatigueScore'],
              ),
            ),

            _row(
              'Alertness',
              _percent(
                signals?[
                    'alertnessScore'],
              ),
            ),

            _row(
              'Eye closure',
              _percent(
                signals?[
                    'eyeClosureScore'],
              ),
            ),
          ],
        ),

        _section(
          title: 'Face Quality',
          icon: Icons.face,
          children: [
            _row(
              'Face detected',
              quality?[
                      'faceDetected']
                  == true
                  ? 'Yes'
                  : 'No',
            ),

            _row(
              'Confidence',
              _percent(
                quality?[
                    'faceConfidence'],
              ),
            ),

            _row(
              'Lighting',
              _percent(
                quality?[
                    'lightingScore'],
              ),
            ),

            _row(
              'Blur score',
              _percent(
                quality?[
                    'blurScore'],
              ),
            ),
          ],
        ),

        _section(
          title: 'Eye Signals',
          icon:
              Icons.remove_red_eye_outlined,
          children: [
            _row(
              'Left eye openness',
              _decimal(
                eyes?[
                    'leftEyeOpenness'],
              ),
            ),

            _row(
              'Right eye openness',
              _decimal(
                eyes?[
                    'rightEyeOpenness'],
              ),
            ),

            _row(
              'Blink count',
              _number(
                eyes?['blinkCount'],
              )
                  .round()
                  .toString(),
            ),

            _row(
              'Prolonged closure',
              eyes?[
                          'prolongedEyeClosure']
                      == true
                  ? 'Yes'
                  : 'No',
            ),
          ],
        ),

        _section(
          title: 'Head Pose',
          icon:
              Icons.threed_rotation,
          children: [
            _row(
              'Yaw',
              '${_decimal(pose?['yaw'])}°',
            ),

            _row(
              'Pitch',
              '${_decimal(pose?['pitch'])}°',
            ),

            _row(
              'Roll',
              '${_decimal(pose?['roll'])}°',
            ),
          ],
        ),

        _section(
          title: 'Face Geometry',
          icon:
              Icons.grid_3x3_rounded,
          children: [
            _row(
              'Face aspect ratio',
              _decimal(
                geometry?[
                    'faceAspectRatio'],
              ),
            ),

            _row(
              'Mouth opening',
              _decimal(
                geometry?[
                    'mouthOpeningRatio'],
              ),
            ),

            _row(
              'Left eye ratio',
              _decimal(
                geometry?[
                    'eyeAspectRatioLeft'],
              ),
            ),

            _row(
              'Right eye ratio',
              _decimal(
                geometry?[
                    'eyeAspectRatioRight'],
              ),
            ),
          ],
        ),

        _section(
          title: 'Skin Appearance',
          icon:
              Icons.auto_awesome,
          children: [
            _row(
              'Brightness',
              _decimal(
                skin?['brightnessMean'],
              ),
            ),

            _row(
              'Texture variance',
              _decimal(
                skin?[
                    'textureVariance'],
              ),
            ),

            _row(
              'Visible skin sheen',
              _percent(
                skin?[
                    'visibleSkinSheenScore'],
              ),
            ),

            _row(
              'Confidence',
              _percent(
                skin?['confidence'],
              ),
            ),
          ],
        ),

        _section(
          title: 'Capture & Storage',
          icon: Icons.camera_alt_rounded,
          children: [
            _row(
              'Capture method',
              capture?['captureMethod']?.toString() ?? 'camera_snapshot',
            ),
            _row(
              'Face captured',
              capture?['captured'] == true ? 'Yes' : 'No',
            ),
            _row(
              'Raw image stored',
              'No',
            ),
          ],
        ),

        const SizedBox(height: 10),

        _info(),
      ],
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 14),

      padding:
          const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(
                icon,
                color:
                    const Color(0xff6c5ce7),
              ),

              const SizedBox(width: 9),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ...children,
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 6,
      ),

      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _percent(dynamic value) {
    return '${(_number(value) * 100).round()}%';
  }

  String _decimal(dynamic value) {
    return _number(value)
        .toStringAsFixed(2);
  }

  Widget _info() {
    return Container(
      padding:
          const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.orange
            .withOpacity(.08),
        borderRadius:
            BorderRadius.circular(16),
      ),

      child: const Text(
        'These measurements represent computer-vision signals extracted from the image. They should not be interpreted as a medical diagnosis.',
        style: TextStyle(
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}
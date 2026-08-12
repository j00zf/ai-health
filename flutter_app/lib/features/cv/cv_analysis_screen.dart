import 'package:flutter/material.dart';

import 'cv_camera_screen.dart';
import 'cv_history_screen.dart';

class CVAnalysisScreen extends StatefulWidget {
  const CVAnalysisScreen({super.key});

  @override
  State<CVAnalysisScreen> createState() => _CVAnalysisScreenState();
}

class _CVAnalysisScreenState extends State<CVAnalysisScreen> {
  Map<String, dynamic>? _result;
  bool _openingCamera = false;

  Future<void> _captureFace() async {
    if (_openingCamera) return;

    setState(() => _openingCamera = true);

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const CVCameraScreen()),
    );

    if (!mounted) return;

    setState(() {
      _openingCamera = false;
      if (result != null) {
        _result = result;
      }
    });
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _percent(dynamic value) {
    return '${(_number(value) * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7f6),
      appBar: AppBar(
        title: const Text('Computer Vision'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Capture history',
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CVHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _result == null ? _buildStartView() : _buildResultView(),
    );
  }

  Widget _buildStartView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff6c5ce7), Color(0xff9f6eff)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.face_retouching_natural,
                  color: Colors.white,
                  size: 42,
                ),
                SizedBox(height: 18),
                Text(
                  'Capture & Analyse Your Face',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Capture a real camera frame, read facial features on the device, and save the extracted CV data to your account.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'What will be captured?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          _featureCard(
            Icons.remove_red_eye_outlined,
            'Eye signals',
            'Eye openness, closure state and blink information.',
          ),
          _featureCard(
            Icons.face_outlined,
            'Face geometry',
            'Face size, aspect ratio and relative face area.',
          ),
          _featureCard(
            Icons.screen_rotation_alt_rounded,
            'Head pose',
            'Head yaw, pitch and roll from the captured frame.',
          ),
          _featureCard(
            Icons.mood_outlined,
            'Expression',
            'Smile probability where supported by ML Kit.',
          ),
          _featureCard(
            Icons.light_mode_outlined,
            'Appearance',
            'Basic face-region brightness information.',
          ),
          const SizedBox(height: 12),
          _privacyCard(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openingCamera ? null : _captureFace,
              icon: _openingCamera
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.camera_alt_rounded),
              label: Text(
                _openingCamera ? 'Opening camera...' : 'Capture Face',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff6c5ce7),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 58),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xff6c5ce7).withOpacity(.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: const Color(0xff6c5ce7)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _privacyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'The captured frame is read by ML Kit on the device. This backend flow saves extracted CV measurements, not the raw face image. These signals are non-clinical and are not a diagnosis.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final result = _result ?? {};
    final quality = _map(result['imageQuality']);
    final eyes = _map(result['eyeSignals']);
    final geometry = _map(result['geometry']);
    final pose = _map(result['headPose']);
    final skin = _map(result['skinAppearance']);
    final derived = _map(result['derivedSignals']);
    final capture = _map(result['captureMetadata']);

    final saved = result['_id'] != null || capture['captured'] == true;
    final faceDetected = quality['faceDetected'] == true;

    return RefreshIndicator(
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statusCard(
            saved: saved,
            faceDetected: faceDetected,
            capturedAt: result['capturedAt']?.toString() ?? '',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _resultCard(
                  'Visual fatigue',
                  _percent(derived['visualFatigueScore']),
                  Icons.battery_alert_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _resultCard(
                  'Alertness',
                  _percent(derived['alertnessScore']),
                  Icons.visibility_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _section(
            'Face Quality',
            Icons.face,
            [
              _dataRow('Face detected', faceDetected ? 'Yes' : 'No'),
              _dataRow('Confidence', _percent(quality['faceConfidence'])),
              _dataRow('Lighting', _percent(quality['lightingScore'])),
              _dataRow('Face size', _percent(quality['faceSizeRatio'])),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            'Eye Signals',
            Icons.remove_red_eye_outlined,
            [
              _dataRow('Left eye openness', _percent(eyes['leftEyeOpenness'])),
              _dataRow('Right eye openness', _percent(eyes['rightEyeOpenness'])),
              _dataRow('Blink count', '${eyes['blinkCount'] ?? 0}'),
              _dataRow(
                'Prolonged closure',
                eyes['prolongedEyeClosure'] == true ? 'Yes' : 'No',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            'Head Pose',
            Icons.screen_rotation_alt_rounded,
            [
              _dataRow('Yaw', '${_number(pose['yaw']).toStringAsFixed(1)}°'),
              _dataRow('Pitch', '${_number(pose['pitch']).toStringAsFixed(1)}°'),
              _dataRow('Roll', '${_number(pose['roll']).toStringAsFixed(1)}°'),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            'Face Geometry',
            Icons.grid_3x3_rounded,
            [
              _dataRow(
                'Face aspect ratio',
                _number(geometry['faceAspectRatio']).toStringAsFixed(3),
              ),
              _dataRow(
                'Face width',
                '${_number(geometry['faceWidth']).toStringAsFixed(1)} px',
              ),
              _dataRow(
                'Face height',
                '${_number(geometry['faceHeight']).toStringAsFixed(1)} px',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            'Appearance',
            Icons.light_mode_outlined,
            [
              _dataRow(
                'Brightness',
                _number(skin['brightnessMean']).toStringAsFixed(1),
              ),
              _dataRow('Skin sheen', 'Not clinically measurable'),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            'Capture & Storage',
            Icons.save_rounded,
            [
              _dataRow('Capture method', capture['captureMethod']?.toString() ?? 'camera_snapshot'),
              _dataRow('Raw image stored', 'No'),
              _dataRow('Backend record', saved ? 'Saved' : 'Local result'),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff6c5ce7).withOpacity(.07),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'These are computer-vision indicators. Visual fatigue and alertness are heuristic signals and should not be treated as medical measurements or diagnoses.',
              style: TextStyle(fontSize: 12, height: 1.5, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _captureFace,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Capture Another Face'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff6c5ce7),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Widget _statusCard({
    required bool saved,
    required bool faceDetected,
    required String capturedAt,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: saved && faceDetected
            ? Colors.green.withOpacity(.10)
            : Colors.orange.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            saved && faceDetected
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            color: saved && faceDetected ? Colors.green : Colors.orange,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saved ? 'Face captured and saved' : 'Face analysed',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  capturedAt.isEmpty ? 'Just now' : capturedAt,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff6c5ce7)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xff6c5ce7)),
              const SizedBox(width: 9),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _dataRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/services/cv_service.dart';

class CVCameraScreen extends StatefulWidget {
  const CVCameraScreen({
    super.key,
  });

  @override
  State<CVCameraScreen> createState() =>
      _CVCameraScreenState();
}

class _CVCameraScreenState
    extends State<CVCameraScreen> {

  final CVService _cvService =
      CVService();

  bool _analyzing = false;

  String _status =
      'Position your face inside the frame';

  Future<void> _analyze() async {
    setState(() {
      _analyzing = true;
      _status =
          'Analyzing facial features...';
    });

    try {
      /*
       * TEMPORARY DEMO PAYLOAD
       *
       * Replace these values with the
       * MediaPipe/OpenCV output.
       */

      final features = {
        'capturedAt':
            DateTime.now().toIso8601String(),

        'source': 'camera',

        'modelName':
            'mediapipe-face-landmarker',

        'modelVersion': '1.0.0',

        'imageQuality': {
          'faceDetected': true,
          'faceConfidence': 0.98,
          'lightingScore': 0.91,
          'blurScore': 0.88,
          'faceSizeRatio': 0.42,
        },

        'geometry': {
          'faceAspectRatio': 0.91,
          'eyeAspectRatioLeft': 0.27,
          'eyeAspectRatioRight': 0.25,
          'mouthOpeningRatio': 0.11,
          'browEyeDistanceLeft': 0.08,
          'browEyeDistanceRight': 0.09,
        },

        'eyeSignals': {
          'leftEyeOpenness': 0.42,
          'rightEyeOpenness': 0.39,
          'blinkDetected': true,
          'blinkCount': 14,
          'prolongedEyeClosure': false,
          'eyeClosureDurationMs': 420,
        },

        'headPose': {
          'yaw': -4.2,
          'pitch': 8.1,
          'roll': 1.3,
        },

        'blendshapes': {
          'eyeBlinkLeft': 0.12,
          'eyeBlinkRight': 0.16,
          'eyeSquintLeft': 0.21,
          'eyeSquintRight': 0.18,
          'eyeWideLeft': 0.03,
          'eyeWideRight': 0.04,
          'jawOpen': 0.08,
          'mouthSmileLeft': 0.01,
          'mouthSmileRight': 0.02,
          'browDownLeft': 0.13,
          'browDownRight': 0.15,
          'browInnerUp': 0.10,
        },

        'skinAppearance': {
          'brightnessMean': 142.3,
          'specularHighlightRatio': 0.083,
          'textureVariance': 21.7,
          'visibleSkinSheenScore': 0.64,
          'confidence': 0.58,
        },

        'derivedSignals': {
          'visualFatigueScore': 0.68,
          'visualFatigueConfidence': 0.72,
          'eyeClosureScore': 0.61,
          'alertnessScore': 0.41,
          'visibleSkinSheenScore': 0.64,
        },
      };

      final result =
          await _cvService.analyze(
        features: features,
      );

      if (!mounted) return;

      setState(() {
        _analyzing = false;
        _status =
            'Analysis completed successfully';
      });

      await Future.delayed(
        const Duration(
          milliseconds: 600,
        ),
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        result,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _analyzing = false;
        _status =
            'Analysis failed. Please try again.';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'CV Face Analysis',
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment:
                    Alignment.center,

                children: [
                  Container(
                    margin:
                        const EdgeInsets.all(25),

                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                        30,
                      ),

                      border: Border.all(
                        color:
                            const Color(
                          0xff6c5ce7,
                        ),
                        width: 3,
                      ),
                    ),

                    child: const Center(
                      child: Icon(
                        Icons.face,
                        color: Colors.white,
                        size: 130,
                      ),
                    ),
                  ),

                  Positioned(
                    top: 45,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),

                      decoration:
                          BoxDecoration(
                        color: Colors.black
                            .withOpacity(.6),
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),

                      child: const Text(
                        'Face detection area',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                25,
              ),

              decoration:
                  const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),

              child: Column(
                children: [
                  Text(
                    _status,
                    textAlign:
                        TextAlign.center,

                    style: const TextStyle(
                      fontSize: 14,
                      color:
                          Colors.black54,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  SizedBox(
                    width: double.infinity,

                    child:
                        ElevatedButton.icon(
                      onPressed:
                          _analyzing
                              ? null
                              : _analyze,

                      icon: _analyzing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .analytics_rounded,
                            ),

                      label: Text(
                        _analyzing
                            ? 'Analyzing...'
                            : 'Capture & Analyze',
                      ),

                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            const Color(
                          0xff6c5ce7,
                        ),
                        foregroundColor:
                            Colors.white,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 15,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
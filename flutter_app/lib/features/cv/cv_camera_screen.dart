import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';


import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

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

  // ===========================================================================
  // CAMERA
  // ===========================================================================

  CameraController? _cameraController;

  List<CameraDescription> _cameras = [];

  bool _cameraInitialized = false;

  bool _initializing = true;

  String? _error;

  // ===========================================================================
  // FACE DETECTOR
  // ===========================================================================

  late final FaceDetector _faceDetector;

  bool _isProcessingFrame = false;

  DateTime _lastProcessed =
      DateTime.fromMillisecondsSinceEpoch(0);

  // Process approximately 4 frames per second.
  static const Duration _processingInterval =
      Duration(milliseconds: 250);

  // ===========================================================================
  // LIVE DATA
  // ===========================================================================

  int _faceCount = 0;

  double? _leftEyeOpen;

  double? _rightEyeOpen;

  double? _smileProbability;

  double? _headYaw;

  double? _headPitch;

  double? _headRoll;

  double? _faceWidth;

  double? _faceHeight;

  double? _faceArea;

  double? _faceConfidence;

  // ===========================================================================
  // HISTORY / AGGREGATION
  // ===========================================================================

  final List<double> _fatigueSamples = [];

  final List<double> _alertnessSamples = [];

  int _blinkCount = 0;

  bool _previousEyesClosed = false;

  DateTime? _eyesClosedSince;

  double? _skinBrightness;

  // Upload / capture state
  final CVService _cvService = CVService();
  bool _capturing = false;

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _faceDetector =
        FaceDetector(
      options:
          FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        enableContours: true,
        enableTracking: true,
        performanceMode:
            FaceDetectorMode.fast,
      ),
    );

    _initialize();
  }

  // ===========================================================================
  // INITIALIZE
  // ===========================================================================

  Future<void> _initialize() async {
    try {
      final permission =
          await Permission.camera.status;

      if (!permission.isGranted) {
        final result =
            await Permission.camera.request();

        if (!result.isGranted) {
          if (!mounted) return;

          setState(() {
            _initializing = false;

            _error =
                result.isPermanentlyDenied
                    ? 'Camera permission is permanently denied.'
                    : 'Camera permission is required.';
          });

          return;
        }
      }

      await _initializeCamera();
    } catch (e) {
      debugPrint(
        '[CV] Initialization error: $e',
      );

      if (!mounted) return;

      setState(() {
        _initializing = false;

        _error =
            'Unable to initialize camera: $e';
      });
    }
  }

  // ===========================================================================
  // CAMERA INITIALIZATION
  // ===========================================================================

  Future<void> _initializeCamera() async {
    _cameras =
        await availableCameras();

    if (_cameras.isEmpty) {
      throw Exception(
        'No camera was found on this device.',
      );
    }

    CameraDescription selectedCamera;

    final frontCameras =
        _cameras.where(
      (camera) =>
          camera.lensDirection ==
          CameraLensDirection.front,
    );

    if (frontCameras.isNotEmpty) {
      selectedCamera =
          frontCameras.first;
    } else {
      selectedCamera =
          _cameras.first;
    }

    _cameraController =
        CameraController(
      selectedCamera,

      ResolutionPreset.medium,

      enableAudio: false,

      imageFormatGroup:
          ImageFormatGroup.yuv420,
    );

    await _cameraController!
        .initialize();

    await _cameraController!
        .startImageStream(
      _processCameraImage,
    );

    if (!mounted) return;

    setState(() {
      _cameraInitialized = true;
      _initializing = false;
      _error = null;
    });
  }

  // ===========================================================================
  // CAMERA FRAME PROCESSING
  // ===========================================================================

  Future<void> _processCameraImage(
    CameraImage image,
  ) async {
    if (!_cameraInitialized ||
        _cameraController == null) {
      return;
    }

    if (_isProcessingFrame) {
      return;
    }

    final now = DateTime.now();

    if (now.difference(
          _lastProcessed,
        ) <
        _processingInterval) {
      return;
    }

    _lastProcessed = now;

    _isProcessingFrame = true;

    try {
      final inputImage =
          _convertCameraImage(
        image,
        _cameraController!.description,
      );

      if (inputImage == null) {
        return;
      }

      final faces =
          await _faceDetector
              .processImage(
        inputImage,
      );

      if (!mounted) return;

      if (faces.isEmpty) {
        setState(() {
          _faceCount = 0;

          _leftEyeOpen = null;
          _rightEyeOpen = null;

          _smileProbability = null;

          _headYaw = null;
          _headPitch = null;
          _headRoll = null;

          _faceWidth = null;
          _faceHeight = null;
          _faceArea = null;

          _faceConfidence = null;
        });

        return;
      }

      // Choose the largest face.
      final face =
          faces.reduce(
        (a, b) {
          final areaA =
              a.boundingBox.width *
                  a.boundingBox.height;

          final areaB =
              b.boundingBox.width *
                  b.boundingBox.height;

          return areaA > areaB ? a : b;
        },
      );

      _updateFaceMetrics(
        face,
        image,
      );
    } catch (e) {
      debugPrint(
        '[CV] Frame processing error: $e',
      );
    } finally {
      _isProcessingFrame = false;
    }
  }

  // ===========================================================================
  // CONVERT CAMERA IMAGE TO ML KIT INPUT
  // ===========================================================================

InputImage? _convertCameraImage(
  CameraImage image,
  CameraDescription camera,
) {
  try {
    // ---------------------------------------------------------------
    // Combine all camera planes into one byte array.
    // ---------------------------------------------------------------

    final BytesBuilder bytesBuilder =
        BytesBuilder(copy: false);

    for (final Plane plane in image.planes) {
      bytesBuilder.add(plane.bytes);
    }

    final Uint8List bytes =
        bytesBuilder.takeBytes();

    // ---------------------------------------------------------------
    // Image size
    // ---------------------------------------------------------------

    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    // ---------------------------------------------------------------
    // Camera rotation
    // ---------------------------------------------------------------

    final InputImageRotation? imageRotation =
        InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );

    if (imageRotation == null) {
      debugPrint(
        '[CV] Unsupported camera rotation: '
        '${camera.sensorOrientation}',
      );

      return null;
    }

    // ---------------------------------------------------------------
    // Image format
    // ---------------------------------------------------------------

    final InputImageFormat? inputImageFormat =
        InputImageFormatValue.fromRawValue(
      image.format.raw,
    );

    if (inputImageFormat == null) {
      debugPrint(
        '[CV] Unsupported image format: '
        '${image.format.raw}',
      );

      return null;
    }

    // ---------------------------------------------------------------
    // Metadata
    // ---------------------------------------------------------------

    final InputImageMetadata metadata =
        InputImageMetadata(
      size: imageSize,

      rotation: imageRotation,

      format: inputImageFormat,

      bytesPerRow:
          image.planes.first.bytesPerRow,
    );

    // ---------------------------------------------------------------
    // ML Kit input
    // ---------------------------------------------------------------

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  } catch (e, stackTrace) {
    debugPrint(
      '[CV] Camera image conversion error: $e',
    );

    debugPrint(
      '[CV] Stack trace: $stackTrace',
    );

    return null;
  }
}
  // ===========================================================================
  // UPDATE FACE METRICS
  // ===========================================================================

  void _updateFaceMetrics(
    Face face,
    CameraImage image,
  ) {
    final box =
        face.boundingBox;

    final width =
        box.width;

    final height =
        box.height;

    final area =
        width * height;

    final imageArea =
        image.width *
            image.height;

    final normalizedArea =
        imageArea > 0
            ? area / imageArea
            : 0.0;

    final leftEye =
        face.leftEyeOpenProbability;

    final rightEye =
        face.rightEyeOpenProbability;

    final smile =
        face.smilingProbability;

    final yaw =
        face.headEulerAngleY;

    final pitch =
        face.headEulerAngleX;

    final roll =
        face.headEulerAngleZ;

    // -------------------------------------------------------------------------
    // EYE / BLINK
    // -------------------------------------------------------------------------

    if (leftEye != null &&
        rightEye != null) {
      final eyeOpen =
          (leftEye + rightEye) / 2;

      final eyesClosed =
          eyeOpen < 0.25;

      if (eyesClosed &&
          !_previousEyesClosed) {
        _eyesClosedSince =
            DateTime.now();
      }

      if (!eyesClosed &&
          _previousEyesClosed) {
        if (_eyesClosedSince != null) {
          final duration =
              DateTime.now()
                  .difference(
            _eyesClosedSince!,
          );

          if (duration.inMilliseconds >=
              100) {
            _blinkCount++;
          }
        }

        _eyesClosedSince = null;
      }

      _previousEyesClosed =
          eyesClosed;
    }

    // -------------------------------------------------------------------------
    // FATIGUE HEURISTIC
    // -------------------------------------------------------------------------

    final fatigue =
        _calculateVisualFatigue(
      leftEye:
          leftEye,
      rightEye:
          rightEye,
      pitch:
          pitch,
    );

    final alertness =
        1.0 - fatigue;

    _fatigueSamples.add(
      fatigue,
    );

    _alertnessSamples.add(
      alertness,
    );

    // Keep only the recent window.
    if (_fatigueSamples.length >
        100) {
      _fatigueSamples.removeAt(0);
    }

    if (_alertnessSamples.length >
        100) {
      _alertnessSamples.removeAt(0);
    }

    // -------------------------------------------------------------------------
    // SKIN APPEARANCE
    // -------------------------------------------------------------------------

    final brightness =
        _estimateFaceBrightness(
      image,
      box,
    );

    if (!mounted) return;

    setState(() {
      _faceCount = 1;

      _leftEyeOpen =
          leftEye;

      _rightEyeOpen =
          rightEye;

      _smileProbability =
          smile;

      _headYaw =
          yaw;

      _headPitch =
          pitch;

      _headRoll =
          roll;

      _faceWidth =
          width;

      _faceHeight =
          height;

      _faceArea =
          normalizedArea;

      // ML Kit's Face object does not provide
      // a universally calibrated confidence value
      // for every configuration.
      _faceConfidence =
          1.0;

      _skinBrightness =
          brightness;
    });
  }

  // ===========================================================================
  // VISUAL FATIGUE HEURISTIC
  // ===========================================================================

  double _calculateVisualFatigue({
    required double? leftEye,
    required double? rightEye,
    required double? pitch,
  }) {
    double score = 0;

    int signals = 0;

    if (leftEye != null &&
        rightEye != null) {
      final eyeOpen =
          (leftEye + rightEye) / 2;

      // Lower eye openness → higher visual
      // fatigue indicator.
      final eyeScore =
          (1.0 - eyeOpen)
              .clamp(0.0, 1.0);

      score += eyeScore;
      signals++;
    }

    if (pitch != null) {
      // Large downward head pitch can be
      // an alertness-related visual signal,
      // but is not itself evidence of fatigue.
      final pitchScore =
          ((pitch.abs() - 10) / 35)
              .clamp(0.0, 1.0);

      score += pitchScore;
      signals++;
    }

    if (signals == 0) {
      return 0;
    }

    return (score / signals)
        .clamp(0.0, 1.0);
  }

  // ===========================================================================
  // FACE BRIGHTNESS
  // ===========================================================================

  double? _estimateFaceBrightness(
    CameraImage image,
    Rect faceBox,
  ) {
    try {
      if (image.planes.isEmpty) {
        return null;
      }

      // Y plane contains luminance.
      final plane =
          image.planes.first;

      final bytes =
          plane.bytes;

      if (bytes.isEmpty) {
        return null;
      }

      final centerX =
          faceBox.center.dx
              .clamp(
                0,
                image.width - 1,
              )
              .toInt();

      final centerY =
          faceBox.center.dy
              .clamp(
                0,
                image.height - 1,
              )
              .toInt();

      final index =
          centerY *
                  plane.bytesPerRow +
              centerX;

      if (index < 0 ||
          index >= bytes.length) {
        return null;
      }

      return bytes[index]
          .toDouble();
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // RESULT
  // ===========================================================================

  Map<String, dynamic> getCurrentResult() {
    final fatigue = _average(_fatigueSamples).clamp(0.0, 1.0);
    final alertness = _average(_alertnessSamples).clamp(0.0, 1.0);

    final eyeOpen = (_leftEyeOpen != null && _rightEyeOpen != null)
        ? ((_leftEyeOpen! + _rightEyeOpen!) / 2).clamp(0.0, 1.0)
        : 0.0;

    final faceWidth = _faceWidth ?? 0.0;
    final faceHeight = _faceHeight ?? 0.0;
    final faceAspectRatio = faceHeight > 0 ? faceWidth / faceHeight : 0.0;

    final prolongedClosure = _eyesClosedSince != null &&
        DateTime.now().difference(_eyesClosedSince!).inMilliseconds >= 1000;

    return {
      'capturedAt': DateTime.now().toUtc().toIso8601String(),
      'source': 'camera',
      'modelName': 'google-mlkit-face-detection',
      'modelVersion': '1.0.0',

      'imageQuality': {
        'faceDetected': _faceCount > 0,
        'faceConfidence': _faceConfidence ?? 0.0,
        'lightingScore': _lightingScore(_skinBrightness),
        'blurScore': 0.0,
        'faceSizeRatio': _faceArea ?? 0.0,
      },

      'geometry': {
        'faceAspectRatio': faceAspectRatio,
        'faceWidth': faceWidth,
        'faceHeight': faceHeight,
        'eyeAspectRatioLeft': _leftEyeOpen ?? 0.0,
        'eyeAspectRatioRight': _rightEyeOpen ?? 0.0,
        'mouthOpeningRatio': 0.0,
        'browEyeDistanceLeft': 0.0,
        'browEyeDistanceRight': 0.0,
      },

      'eyeSignals': {
        'leftEyeOpenness': _leftEyeOpen ?? 0.0,
        'rightEyeOpenness': _rightEyeOpen ?? 0.0,
        'blinkDetected': _blinkCount > 0,
        'blinkCount': _blinkCount,
        'prolongedEyeClosure': prolongedClosure,
        'eyeClosureDurationMs': _eyesClosedSince == null
            ? 0
            : DateTime.now().difference(_eyesClosedSince!).inMilliseconds,
      },

      'headPose': {
        'yaw': _headYaw ?? 0.0,
        'pitch': _headPitch ?? 0.0,
        'roll': _headRoll ?? 0.0,
      },

      // ML Kit FaceDetector does not expose MediaPipe blendshape coefficients.
      // Keep these fields zero rather than inventing model output.
      'blendshapes': {
        'eyeBlinkLeft': 0.0,
        'eyeBlinkRight': 0.0,
        'eyeSquintLeft': 0.0,
        'eyeSquintRight': 0.0,
        'eyeWideLeft': 0.0,
        'eyeWideRight': 0.0,
        'jawOpen': 0.0,
        'mouthSmileLeft': _smileProbability ?? 0.0,
        'mouthSmileRight': _smileProbability ?? 0.0,
        'browDownLeft': 0.0,
        'browDownRight': 0.0,
        'browInnerUp': 0.0,
      },

      'skinAppearance': {
        'brightnessMean': _skinBrightness ?? 0.0,
        'specularHighlightRatio': 0.0,
        'textureVariance': 0.0,
        'visibleSkinSheenScore': 0.0,
        'confidence': _faceConfidence ?? 0.0,
      },

      'derivedSignals': {
        'visualFatigueScore': fatigue,
        'visualFatigueConfidence': _fatigueConfidence(),
        'eyeClosureScore': (1.0 - eyeOpen).clamp(0.0, 1.0),
        'alertnessScore': alertness,
        'visibleSkinSheenScore': 0.0,
      },

      'privacy': {
        'rawImageStored': false,
        'consentGiven': true,
      },

      'disclaimer':
          'Computer-vision signals are non-clinical indicators and are not a medical diagnosis.',
    };
  }

  double _lightingScore(double? brightness) {
    if (brightness == null) return 0.0;
    final normalized = (brightness / 255.0).clamp(0.0, 1.0);
    return (1.0 - (normalized - 0.5).abs() * 2).clamp(0.0, 1.0);
  }

  double _fatigueConfidence() {
    if (_fatigueSamples.length < 5) return 0.30;
    if (_fatigueSamples.length < 20) return 0.55;
    return 0.75;
  }

  double _average(
    List<double> values,
  ) {
    if (values.isEmpty) {
      return 0;
    }

    return values.reduce(
          (a, b) => a + b,
        ) /
        values.length;
  }

  // ===========================================================================
  // STOP CAMERA
  // ===========================================================================

  Future<void> _stopCamera() async {
    try {
      if (_cameraController
              ?.value
              .isStreamingImages ==
          true) {
        await _cameraController!
            .stopImageStream();
      }
    } catch (_) {}

    try {
      await _cameraController
          ?.dispose();
    } catch (_) {}

    _cameraController = null;
  }

  // ===========================================================================
  // FINISH
  // ===========================================================================

  Future<void> _captureAndAnalyse() async {
    if (_capturing) return;

    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera is not ready.')),
      );
      return;
    }

    if (_faceCount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please position your face inside the guide.'),
        ),
      );
      return;
    }

    setState(() => _capturing = true);

    try {
      final controller = _cameraController!;

      // Stop the live stream first so the camera can take a real snapshot.
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }

      // -----------------------------------------------------------------------
      // REAL FACE CAPTURE
      // -----------------------------------------------------------------------
      // The JPEG is captured on the device and immediately read by ML Kit.
      // The raw image is NOT uploaded or stored by this implementation.
      final XFile snapshot = await controller.takePicture();

      // Re-run face detection on the exact captured frame. This means the
      // values saved to the backend belong to the captured face, not merely
      // to an earlier preview frame.
      await _analyseCapturedSnapshot(snapshot.path);

      final payload = getCurrentResult();
      payload['capture'] = {
        'captured': true,
        'captureMethod': 'camera_snapshot',
        'capturedAt': DateTime.now().toUtc().toIso8601String(),
        'rawImageStored': false,
      };

      payload['privacy'] = {
        'rawImageStored': false,
        'consentGiven': true,
      };

      // Save the extracted CV data to MongoDB through the authenticated API.
      final response = await _cvService.saveCapture(features: payload);
      final analysis = response['analysis'];

      await _stopCamera();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Face captured, analysed and saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(
        context,
        analysis is Map
            ? Map<String, dynamic>.from(analysis)
            : payload,
      );
    } catch (e) {
      debugPrint('[CV] Capture/upload error: $e');

      if (!mounted) return;

      setState(() => _capturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Face capture failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _analyseCapturedSnapshot(String path) async {
    try {
      final input = InputImage.fromFilePath(path);
      final faces = await _faceDetector.processImage(input);

      if (faces.isEmpty) {
        throw Exception('No face was found in the captured image.');
      }

      final face = faces.reduce((a, b) {
        final areaA = a.boundingBox.width * a.boundingBox.height;
        final areaB = b.boundingBox.width * b.boundingBox.height;
        return areaA > areaB ? a : b;
      });

      final box = face.boundingBox;
      final leftEye = face.leftEyeOpenProbability;
      final rightEye = face.rightEyeOpenProbability;
      final smile = face.smilingProbability;
      final yaw = face.headEulerAngleY;
      final pitch = face.headEulerAngleX;
      final roll = face.headEulerAngleZ;

      final imageWidth = _cameraController?.value.previewSize?.height ?? 1;
      final imageHeight = _cameraController?.value.previewSize?.width ?? 1;
      final imageArea = imageWidth * imageHeight;
      final normalizedArea = imageArea > 0
          ? (box.width * box.height) / imageArea
          : 0.0;

      if (!mounted) return;

      setState(() {
        _faceCount = faces.length;
        _leftEyeOpen = leftEye;
        _rightEyeOpen = rightEye;
        _smileProbability = smile;
        _headYaw = yaw;
        _headPitch = pitch;
        _headRoll = roll;
        _faceWidth = box.width;
        _faceHeight = box.height;
        _faceArea = normalizedArea.clamp(0.0, 1.0);
        _faceConfidence = 1.0;
      });
    } catch (e) {
      debugPrint('[CV] Captured image analysis error: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // OPEN SETTINGS
  // ===========================================================================

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _stopCamera();

    _faceDetector.close();

    super.dispose();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.black,

      appBar: AppBar(
        backgroundColor:
            Colors.black,

        foregroundColor:
            Colors.white,

        title: const Text(
          'CV Analysis',
        ),

        actions: [
          IconButton(
            icon:
                const Icon(
              Icons.cameraswitch_rounded,
            ),

            onPressed:
                _switchCamera,
          ),
        ],
      ),

      body: _buildBody(),

      bottomNavigationBar:
          _buildBottomBar(),
    );
  }

  // ===========================================================================
  // BODY
  // ===========================================================================

  Widget _buildBody() {
    if (_initializing) {
      return const Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            CircularProgressIndicator(
              color:
                  Colors.white,
            ),

            SizedBox(
              height: 16,
            ),

            Text(
              'Starting camera...',
              style:
                  TextStyle(
                color:
                    Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(
            24,
          ),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              const Icon(
                Icons
                    .no_photography_rounded,

                color:
                    Colors.white,

                size: 64,
              ),

              const SizedBox(
                height: 20,
              ),

              Text(
                _error!,

                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize: 16,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              ElevatedButton.icon(
                onPressed:
                    _openSettings,

                icon:
                    const Icon(
                  Icons.settings,
                ),

                label:
                    const Text(
                  'Open Settings',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_cameraController == null ||
        !_cameraController!
            .value
            .isInitialized) {
      return const Center(
        child: Text(
          'Camera unavailable',
          style:
              TextStyle(
            color:
                Colors.white,
          ),
        ),
      );
    }

    return Stack(
      fit:
          StackFit.expand,

      children: [
        Center(
          child:
              CameraPreview(
            _cameraController!,
          ),
        ),

        // Face guide.
        Center(
          child: Container(
            width: 270,
            height: 350,

            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                140,
              ),

              border:
                  Border.all(
                color:
                    _faceCount > 0
                        ? Colors.greenAccent
                        : Colors.white70,

                width: 3,
              ),
            ),
          ),
        ),

        // Live status.
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,

          child:
              _buildLiveMetrics(),
        ),
      ],
    );
  }

  // ===========================================================================
  // LIVE METRICS
  // ===========================================================================

  Widget _buildLiveMetrics() {
    final eyeOpen =
        (_leftEyeOpen != null &&
                _rightEyeOpen != null)
            ? ((_leftEyeOpen! +
                    _rightEyeOpen!) /
                2)
            : null;

    final fatigue =
        _average(
      _fatigueSamples,
    );

    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.black.withOpacity(
          0.75,
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,

                decoration:
                    BoxDecoration(
                  color:
                      _faceCount > 0
                          ? Colors.greenAccent
                          : Colors.redAccent,

                  shape:
                      BoxShape.circle,
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Text(
                _faceCount > 0
                    ? 'Face detected'
                    : 'Position your face',

                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          if (_faceCount > 0) ...[
            const SizedBox(
              height: 12,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      _metric(
                    'Eye openness',
                    eyeOpen != null
                        ? '${(eyeOpen * 100).toStringAsFixed(0)}%'
                        : '--',
                  ),
                ),

                Expanded(
                  child:
                      _metric(
                    'Blink count',
                    '$_blinkCount',
                  ),
                ),

                Expanded(
                  child:
                      _metric(
                    'Visual fatigue',
                    '${(fatigue * 100).toStringAsFixed(0)}%',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(
    String title,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          title,

          style:
              const TextStyle(
            color:
                Colors.white60,
            fontSize: 10,
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          value,

          style:
              const TextStyle(
            color:
                Colors.white,
            fontSize: 16,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // BOTTOM BAR
  // ===========================================================================

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_faceCount > 0)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Face detected • Ready to capture and save',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _faceCount > 0 && !_capturing
                    ? _captureAndAnalyse
                    : null,
                icon: _capturing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.camera_alt_rounded),
                label: Text(_capturing ? 'Capturing & Analysing...' : 'Capture Face & Analyse'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6c5ce7),
                  disabledBackgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SWITCH CAMERA
  // ===========================================================================

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) {
      return;
    }

    final current =
        _cameraController
            ?.description;

    if (current == null) {
      return;
    }

    final next =
        _cameras.firstWhere(
      (camera) =>
          camera.lensDirection !=
          current.lensDirection,
      orElse: () =>
          _cameras.first,
    );

    await _cameraController
        ?.stopImageStream();

    await _cameraController
        ?.dispose();

    _cameraController =
        CameraController(
      next,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup:
          ImageFormatGroup.yuv420,
    );

    await _cameraController!
        .initialize();

    await _cameraController!
        .startImageStream(
      _processCameraImage,
    );

    if (!mounted) return;

    setState(() {
      _capturing = false;
      _faceCount = 0;
    });

  }
}
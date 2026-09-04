import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

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

class _CVCameraScreenState extends State<CVCameraScreen>
    with SingleTickerProviderStateMixin {
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

  // ===========================================================================
  // CV SERVICE
  // ===========================================================================

  final CVService _cvService = CVService();

  bool _capturing = false;

  // ===========================================================================
  // GUIDED SCAN
  // ===========================================================================

  int _currentStep = 0;

  bool _scanStarted = false;

  bool _scanCompleted = false;

  String _instruction =
      'Position your face inside the frame';

  String _subInstruction =
      'Keep your face centered and look at the camera';

  // ===========================================================================
  // ANIMATION
  // ===========================================================================

  late final AnimationController _guideAnimationController;

  // ===========================================================================
  // CAPTURE RESULTS
  // ===========================================================================

  final List<Map<String, dynamic>> _captureResults = [];

  // The first straight-facing JPEG is temporarily uploaded to the Node backend,
  // proxied to the Python facial-stress service, and then discarded.
  String? _stressImagePath;

  // Number of blink-like captured samples detected during the scan.
  // Kept as a temporal scan metric rather than an ML Kit confidence value.
  int _blinkCount = 0;

  // ===========================================================================
  // GUIDED STEPS
  // ===========================================================================

  final List<_ScanStep> _scanSteps = const [
    _ScanStep(
      title: 'Look straight',
      instruction:
          'Look directly at the camera',
      icon: Icons.face_retouching_natural,
      duration: Duration(milliseconds: 1200),
    ),
    _ScanStep(
      title: 'Turn slightly left',
      instruction:
          'Slowly turn your face a little to the left',
      icon: Icons.keyboard_arrow_left_rounded,
      duration: Duration(milliseconds: 1300),
    ),
    _ScanStep(
      title: 'Turn slightly right',
      instruction:
          'Slowly turn your face a little to the right',
      icon: Icons.keyboard_arrow_right_rounded,
      duration: Duration(milliseconds: 1300),
    ),
    _ScanStep(
      title: 'Look slightly up',
      instruction:
          'Raise your chin slightly and look up',
      icon: Icons.keyboard_arrow_up_rounded,
      duration: Duration(milliseconds: 1300),
    ),
    _ScanStep(
      title: 'Look slightly down',
      instruction:
          'Lower your chin slightly and look down',
      icon: Icons.keyboard_arrow_down_rounded,
      duration: Duration(milliseconds: 1300),
    ),
  ];

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        enableContours: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    _guideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1200,
      ),
    )..repeat(reverse: true);

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

            _error = result.isPermanentlyDenied
                ? 'Camera permission is permanently denied.'
                : 'Camera permission is required.';
          });

          return;
        }
      }

      await _initializeCamera();
    } catch (e, stackTrace) {
      debugPrint(
        '[CV] Camera initialization error: $e',
      );

      debugPrint(
        '[CV] Stack trace: $stackTrace',
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

    await _createCameraController(
      selectedCamera,
    );
  }

  // ===========================================================================
  // CREATE CAMERA CONTROLLER
  // ===========================================================================

  Future<void> _createCameraController(
    CameraDescription camera,
  ) async {
    final controller =
        CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,

      // We are intentionally NOT using startImageStream.
      //
      // ML Kit analyses the actual JPEG captured by
      // takePicture(), avoiding the Android YUV/NV21
      // InputImage conversion problem.
      imageFormatGroup:
          ImageFormatGroup.jpeg,
    );

    await controller.initialize();

    _cameraController =
        controller;

    if (!mounted) return;

    setState(() {
      _cameraInitialized = true;
      _initializing = false;
      _error = null;
    });
  }

  // ===========================================================================
  // START GUIDED SCAN
  // ===========================================================================

  Future<void> _startGuidedScan() async {
    if (_capturing) {
      return;
    }

    final controller =
        _cameraController;

    if (controller == null ||
        !controller.value.isInitialized) {
      _showMessage(
        'Camera is not ready yet.',
        error: true,
      );

      return;
    }

    setState(() {
      _capturing = true;
      _scanStarted = true;
      _scanCompleted = false;
      _currentStep = 0;
      _captureResults.clear();
      _stressImagePath = null;
      _blinkCount = 0;
    });

    try {
      for (
        int index = 0;
        index < _scanSteps.length;
        index++
      ) {
        if (!mounted) return;

        setState(() {
          _currentStep = index;
          _instruction =
              _scanSteps[index].title;
          _subInstruction =
              _scanSteps[index].instruction;
        });

        // ---------------------------------------------------------------
        // Give the user time to move into position.
        // ---------------------------------------------------------------

        await Future.delayed(
          const Duration(
            milliseconds: 900,
          ),
        );

        if (!mounted) return;

        // ---------------------------------------------------------------
        // Capture real JPEG.
        // ---------------------------------------------------------------

        final snapshot =
            await controller.takePicture();

        // The straight-facing capture is the most suitable single image for
        // the server-side CNN. The file is not persisted by our backend.
        if (index == 0) {
          _stressImagePath = snapshot.path;
        }

        debugPrint(
          '[CV] Captured step ${index + 1}: '
          '${snapshot.path}',
        );

        // ---------------------------------------------------------------
        // Analyse exact captured JPEG.
        // ---------------------------------------------------------------

        final result =
            await _analyseCapturedImage(
          snapshot.path,
          stepIndex: index,
        );

        if (result != null) {
          _captureResults.add(
            result,
          );
        }

        // ---------------------------------------------------------------
        // Small pause before next instruction.
        // ---------------------------------------------------------------

        if (index <
            _scanSteps.length - 1) {
          await Future.delayed(
            const Duration(
              milliseconds: 350,
            ),
          );
        }
      }

      // -----------------------------------------------------------------
      // Validate results.
      // -----------------------------------------------------------------

      if (_captureResults.isEmpty) {
        throw Exception(
          'No face was detected. '
          'Please make sure your face is clearly visible '
          'inside the guide and try again.',
        );
      }

      if (!mounted) return;

      setState(() {
        _instruction =
            'Analysis complete';
        _subInstruction =
            'Preparing your results...';
        _scanCompleted = true;
      });

      // -----------------------------------------------------------------
      // Aggregate all captures.
      // -----------------------------------------------------------------

      final payload =
          _buildAggregatedPayload();

      debugPrint(
        '[CV] Valid captures: '
        '${_captureResults.length}/${_scanSteps.length}',
      );

      debugPrint(
        '[CV] Sending CV features to backend...',
      );

      // -----------------------------------------------------------------
      // Save through existing authenticated API.
      // -----------------------------------------------------------------

      final stressImagePath = _stressImagePath;

      if (stressImagePath == null) {
        throw Exception(
          'The straight-facing image was not captured. Please try again.',
        );
      }

      final response =
          await _cvService.analyzeWithImage(
        features: payload,
        imagePath: stressImagePath,
      );

      final analysis =
          response['analysis'];

      // -----------------------------------------------------------------
      // Cleanup.
      // -----------------------------------------------------------------

      await _stopCamera();

      if (!mounted) return;

      _showMessage(
        'Face captured and analysed successfully.',
      );

      Navigator.pop(
        context,
        analysis is Map
            ? Map<String, dynamic>.from(
                analysis,
              )
            : payload,
      );
    } catch (e, stackTrace) {
      debugPrint(
        '[CV] Guided capture failed: $e',
      );

      debugPrint(
        '[CV] Stack trace: $stackTrace',
      );

      if (!mounted) return;

      setState(() {
        _capturing = false;
        _scanStarted = false;
        _scanCompleted = false;
      });

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        error: true,
      );
    }
  }

  // ===========================================================================
  // ANALYSE ONE CAPTURED JPEG
  // ===========================================================================

  Future<Map<String, dynamic>?>
      _analyseCapturedImage(
    String path, {
    required int stepIndex,
  }) async {
    try {
      debugPrint(
        '[CV] Analysing captured JPEG: $path',
      );

      final inputImage =
          InputImage.fromFilePath(
        path,
      );

      final faces =
          await _faceDetector.processImage(
        inputImage,
      );

      debugPrint(
        '[CV] Faces detected in step '
        '${stepIndex + 1}: ${faces.length}',
      );

      if (faces.isEmpty) {
        debugPrint(
          '[CV] No face detected in step '
          '${stepIndex + 1}',
        );

        return null;
      }

      // ---------------------------------------------------------------
      // Select largest face.
      // ---------------------------------------------------------------

      final face =
          faces.reduce(
        (a, b) {
          final areaA =
              a.boundingBox.width *
                  a.boundingBox.height;

          final areaB =
              b.boundingBox.width *
                  b.boundingBox.height;

          return areaA > areaB
              ? a
              : b;
        },
      );

      final box =
          face.boundingBox;

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

      final eyeValues =
          <double>[];

      if (leftEye != null) {
        eyeValues.add(leftEye);
      }

      if (rightEye != null) {
        eyeValues.add(rightEye);
      }

      final eyeOpen =
          eyeValues.isEmpty
              ? 0.0
              : eyeValues.reduce(
                    (a, b) => a + b,
                  ) /
                  eyeValues.length;

      final fatigue =
          _calculateVisualFatigue(
        leftEye: leftEye,
        rightEye: rightEye,
        pitch: pitch,
      );

      final alertness =
          (1.0 - fatigue)
              .clamp(0.0, 1.0);

      final prolongedClosure =
          eyeOpen < 0.25;

      Size? imageSize;
      try {
        final decoded = await decodeImageFromList(await File(path).readAsBytes());
        imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
      } catch (e) {
        debugPrint('Could not read image size: $e');
      }

      final faceAreaRatio =
          _calculateFaceAreaRatio(
        box,
        imageSize,
      );

      // ---------------------------------------------------------------
      // We don't use a fake ML confidence value.
      //
      // The value represents whether ML Kit successfully detected
      // a face and how large that face is in the captured image.
      // ---------------------------------------------------------------

      final confidence =
          _calculateDetectionConfidence(
        faceAreaRatio,
      );

      return {
        'stepIndex': stepIndex,

        'step':
            _scanSteps[stepIndex]
                .title,

        'faceCount':
            faces.length,

        'faceDetected':
            true,

        'faceWidth':
            box.width,

        'faceHeight':
            box.height,

        'faceAreaRatio':
            faceAreaRatio,

        'faceConfidence':
            confidence,

        'leftEyeOpen':
            leftEye ?? 0.0,

        'rightEyeOpen':
            rightEye ?? 0.0,

        'eyeOpen':
            eyeOpen,

        'smileProbability':
            smile ?? 0.0,

        'yaw':
            yaw ?? 0.0,

        'pitch':
            pitch ?? 0.0,

        'roll':
            roll ?? 0.0,

        'fatigue':
            fatigue,

        'alertness':
            alertness,

        'prolongedEyeClosure':
            prolongedClosure,
      };
    } catch (e, stackTrace) {
      debugPrint(
        '[CV] Captured image analysis error: $e',
      );

      debugPrint(
        '[CV] Stack trace: $stackTrace',
      );

      return null;
    }
  }

  // ===========================================================================
  // BUILD AGGREGATED PAYLOAD
  // ===========================================================================

  Map<String, dynamic>
      _buildAggregatedPayload() {
    final captures =
        _captureResults;

    final fatigue =
        _averageByKey(
      captures,
      'fatigue',
    );

    final alertness =
        _averageByKey(
      captures,
      'alertness',
    );

    final leftEye =
        _averageByKey(
      captures,
      'leftEyeOpen',
    );

    final rightEye =
        _averageByKey(
      captures,
      'rightEyeOpen',
    );

    final eyeOpen =
        _averageByKey(
      captures,
      'eyeOpen',
    );

    final smile =
        _averageByKey(
      captures,
      'smileProbability',
    );

    final yaw =
        _averageByKey(
      captures,
      'yaw',
    );

    final pitch =
        _averageByKey(
      captures,
      'pitch',
    );

    final roll =
        _averageByKey(
      captures,
      'roll',
    );

    final faceWidth =
        _averageByKey(
      captures,
      'faceWidth',
    );

    final faceHeight =
        _averageByKey(
      captures,
      'faceHeight',
    );

    final faceAreaRatio =
        _averageByKey(
      captures,
      'faceAreaRatio',
    );

    final confidence =
        _averageByKey(
      captures,
      'faceConfidence',
    );

    final prolongedClosureCount =
        captures.where(
      (item) =>
          item['prolongedEyeClosure'] ==
          true,
    ).length;

    final blinkLikeCaptures =
        captures.where(
      (item) {
        final value =
            _number(
          item['eyeOpen'],
        );

        return value > 0 &&
            value < 0.25;
      },
    ).length;

    return {
      // -----------------------------------------------------------------
      // Metadata
      // -----------------------------------------------------------------

      'capturedAt':
          DateTime.now()
              .toUtc()
              .toIso8601String(),

      'source':
          'camera',

      'modelName':
          'google-mlkit-face-detection+facial-stress-cnn',

      'modelVersion':
          '1.1.0',

      'capture': {
        'captured': true,
        'captureMethod': 'camera_snapshot',
        'capturedAt': DateTime.now().toUtc().toIso8601String(),
      },

      // -----------------------------------------------------------------
      // Image quality
      // -----------------------------------------------------------------

      'imageQuality': {
        'faceDetected':
            captures.isNotEmpty,

        'faceCount':
            captures.isNotEmpty
                ? captures
                    .map(
                      (e) =>
                          _number(
                        e['faceCount'],
                      ),
                    )
                    .reduce(
                      math.max,
                    )
                    .toInt()
                : 0,

        'faceConfidence':
            confidence,

        'faceSizeRatio':
            faceAreaRatio,
      },

      // -----------------------------------------------------------------
      // Geometry
      // -----------------------------------------------------------------

      'geometry': {
        'faceWidth':
            faceWidth,

        'faceHeight':
            faceHeight,

        'faceAreaRatio':
            faceAreaRatio,

        'faceAspectRatio':
            faceHeight > 0
                ? faceWidth /
                    faceHeight
                : 0.0,

        'eyeAspectRatioLeft':
            leftEye,

        'eyeAspectRatioRight':
            rightEye,

        'mouthOpeningRatio':
            0.0,

        'browEyeDistanceLeft':
            0.0,

        'browEyeDistanceRight':
            0.0,
      },

      // -----------------------------------------------------------------
      // Eye signals
      // -----------------------------------------------------------------

      'eyeSignals': {
        'leftEyeOpenness':
            leftEye,

        'rightEyeOpenness':
            rightEye,

        'averageEyeOpen':
            eyeOpen,

        'blinkDetected':
            blinkLikeCaptures > 0,

        'blinkCount':
            _blinkCount,

        'prolongedEyeClosure':
            prolongedClosureCount > 0,

        'eyeClosureDurationMs':
            0,

        'capturedEyeClosureSamples':
            prolongedClosureCount,
      },

      // -----------------------------------------------------------------
      // Head pose
      // -----------------------------------------------------------------

      'headPose': {
        'yaw':
            yaw,

        'pitch':
            pitch,

        'roll':
            roll,
      },

      // -----------------------------------------------------------------
      // Blendshapes
      //
      // ML Kit does not provide MediaPipe blendshape
      // coefficients through this API.
      // -----------------------------------------------------------------

      'blendshapes': {
        'eyeBlinkLeft':
            0.0,

        'eyeBlinkRight':
            0.0,

        'eyeSquintLeft':
            0.0,

        'eyeSquintRight':
            0.0,

        'eyeWideLeft':
            0.0,

        'eyeWideRight':
            0.0,

        'jawOpen':
            0.0,

        'mouthSmileLeft':
            smile,

        'mouthSmileRight':
            smile,

        'browDownLeft':
            0.0,

        'browDownRight':
            0.0,

        'browInnerUp':
            0.0,
      },

      // -----------------------------------------------------------------
      // Skin appearance
      //
      // We intentionally do not claim actual clinical skin metrics.
      // -----------------------------------------------------------------

      'skinAppearance': {
        'brightnessMean':
            0.0,

        'specularHighlightRatio':
            0.0,

        'textureVariance':
            0.0,

        'visibleSkinSheenScore':
            0.0,

        'confidence':
            0.0,
      },

      // -----------------------------------------------------------------
      // Derived visual signals
      // -----------------------------------------------------------------

      'derivedSignals': {
        'visualFatigueScore':
            fatigue,

        'visualFatigueConfidence':
            _fatigueConfidence(
          captures.length,
        ),

        'eyeClosureScore':
            (1.0 - eyeOpen)
                .clamp(0.0, 1.0),

        'alertnessScore':
            alertness,

        'visibleSkinSheenScore':
            0.0,
      },

      // -----------------------------------------------------------------
      // Privacy
      // -----------------------------------------------------------------

      'privacy': {
        'rawImageStored':
            false,

        // One JPEG is transmitted temporarily for inference and discarded.
        'rawImageTemporarilyProcessed':
            true,

        'consentGiven':
            true,
      },

      // -----------------------------------------------------------------
      // Individual capture information
      //
      // Useful for future detail screens/trends.
      // -----------------------------------------------------------------

      'captureSamples':
          captures,

      // -----------------------------------------------------------------
      // Disclaimer
      // -----------------------------------------------------------------

      'disclaimer':
          'Computer-vision signals are non-clinical indicators and are not a medical diagnosis.',
    };
  }

  // ===========================================================================
  // FATIGUE
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
          (leftEye + rightEye) /
              2;

      final eyeScore =
          (1.0 - eyeOpen)
              .clamp(0.0, 1.0);

      score += eyeScore;

      signals++;
    }

    if (pitch != null) {
      final pitchScore =
          ((pitch.abs() - 10) /
                  35)
              .clamp(0.0, 1.0);

      score += pitchScore;

      signals++;
    }

    if (signals == 0) {
      return 0.0;
    }

    return (score / signals)
        .clamp(0.0, 1.0);
  }

  // ===========================================================================
  // FACE AREA
  // ===========================================================================

  double _calculateFaceAreaRatio(
    Rect face,
    Size? imageSize,
  ) {
    if (imageSize == null ||
        imageSize.width <= 0 ||
        imageSize.height <= 0) {
      return 0.0;
    }

    final imageArea =
        imageSize.width *
            imageSize.height;

    if (imageArea <= 0) {
      return 0.0;
    }

    return (
      face.width *
          face.height
    ) /
        imageArea;
  }

  // ===========================================================================
  // DETECTION CONFIDENCE
  // ===========================================================================

  double _calculateDetectionConfidence(
    double faceAreaRatio,
  ) {
    if (faceAreaRatio <= 0) {
      return 0.0;
    }

    // This is a usability/geometry score,
    // NOT a calibrated ML Kit confidence value.
    return (faceAreaRatio * 5.0)
        .clamp(0.0, 1.0);
  }

  // ===========================================================================
  // AVERAGE
  // ===========================================================================

  double _averageByKey(
    List<Map<String, dynamic>>
        values,
    String key,
  ) {
    if (values.isEmpty) {
      return 0.0;
    }

    final numbers =
        values
            .map(
              (item) =>
                  _number(
                item[key],
              ),
            )
            .toList();

    if (numbers.isEmpty) {
      return 0.0;
    }

    return numbers.reduce(
          (a, b) => a + b,
        ) /
        numbers.length;
  }

  // ===========================================================================
  // NUMBER
  // ===========================================================================

  double _number(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  // ===========================================================================
  // FATIGUE CONFIDENCE
  // ===========================================================================

  double _fatigueConfidence(
    int samples,
  ) {
    if (samples <= 0) {
      return 0.0;
    }

    if (samples < 2) {
      return 0.30;
    }

    if (samples < 4) {
      return 0.55;
    }

    return 0.75;
  }

  // ===========================================================================
  // STOP CAMERA
  // ===========================================================================

  Future<void> _stopCamera() async {
    try {
      await _cameraController
          ?.dispose();
    } catch (e) {
      debugPrint(
        '[CV] Camera dispose error: $e',
      );
    }

    _cameraController = null;
  }

  // ===========================================================================
  // SWITCH CAMERA
  // ===========================================================================

  Future<void> _switchCamera() async {
    if (_capturing) {
      return;
    }

    if (_cameras.length < 2) {
      _showMessage(
        'No second camera is available.',
      );

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

    try {
      setState(() {
        _cameraInitialized = false;
      });

      await _cameraController
          ?.dispose();

      _cameraController = null;

      await _createCameraController(
        next,
      );

      if (!mounted) return;

      setState(() {
        _faceCountReset();
      });
    } catch (e) {
      debugPrint(
        '[CV] Camera switch error: $e',
      );

      if (!mounted) return;

      setState(() {
        _error =
            'Unable to switch camera: $e';
        _cameraInitialized = false;
      });
    }
  }

  void _faceCountReset() {
    _currentStep = 0;
    _scanStarted = false;
    _scanCompleted = false;
  }

  // ===========================================================================
  // SETTINGS
  // ===========================================================================

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              error
                  ? Colors.redAccent
                  : Colors.green,
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
      );
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _guideAnimationController.dispose();

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
        elevation: 0,

        title: const Text(
          'Stress Scan',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),

        actions: [
          IconButton(
            tooltip:
                'Switch camera',
            icon: const Icon(
              Icons
                  .cameraswitch_rounded,
            ),
            onPressed:
                _capturing
                    ? null
                    : _switchCamera,
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
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError();
    }

    if (_cameraController == null ||
        !_cameraInitialized ||
        !_cameraController!
            .value
            .isInitialized) {
      return const Center(
        child: Text(
          'Camera unavailable',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      );
    }

    return _buildCamera();
  }

  // ===========================================================================
  // LOADING
  // ===========================================================================

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.white,
          ),
          SizedBox(height: 18),
          Text(
            'Starting camera...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ERROR
  // ===========================================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration:
                  BoxDecoration(
                color:
                    Colors.white10,
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .no_photography_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            Text(
              _error!,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
            ),

            const SizedBox(
              height: 26,
            ),

            ElevatedButton.icon(
              onPressed:
                  _openSettings,
              icon: const Icon(
                Icons.settings_rounded,
              ),
              label: const Text(
                'Open Settings',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CAMERA
  // ===========================================================================

  Widget _buildCamera() {
    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
        return Stack(
          fit:
              StackFit.expand,
          children: [
            // ---------------------------------------------------------------
            // Camera preview
            // ---------------------------------------------------------------

            _buildCameraPreview(),

            // ---------------------------------------------------------------
            // Top instruction
            // ---------------------------------------------------------------

            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child:
                  _buildInstructionCard(),
            ),

            // ---------------------------------------------------------------
            // Face guide
            // ---------------------------------------------------------------

            Center(
              child:
                  _buildAnimatedFaceGuide(),
            ),

            // ---------------------------------------------------------------
            // Direction indicator
            // ---------------------------------------------------------------

            if (_scanStarted &&
                !_scanCompleted)
              Positioned(
                left: 0,
                right: 0,
                bottom: 118,
                child:
                    _buildDirectionHint(),
              ),

            // ---------------------------------------------------------------
            // Bottom information
            // ---------------------------------------------------------------

            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child:
                  _buildCameraStatus(),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // CAMERA PREVIEW
  // ===========================================================================

  Widget _buildCameraPreview() {
    final controller =
        _cameraController!;

    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width:
                controller
                    .value
                    .previewSize
                    ?.height ??
                1,
            height:
                controller
                    .value
                    .previewSize
                    ?.width ??
                1,
            child:
                CameraPreview(
              controller,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // INSTRUCTION CARD
  // ===========================================================================

  Widget _buildInstructionCard() {
    final step =
        _scanStarted
            ? _currentStep + 1
            : 0;

    return AnimatedContainer(
      duration:
          const Duration(
        milliseconds: 250,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.black.withOpacity(
          0.68,
        ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border:
            Border.all(
          color:
              Colors.white.withOpacity(
            0.10,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xff6c5ce7,
              ).withOpacity(
                0.9,
              ),
              shape:
                  BoxShape.circle,
            ),
            child: Icon(
              _scanStarted
                  ? _scanSteps[
                          _currentStep]
                      .icon
                  : Icons.face_rounded,
              color:
                  Colors.white,
              size: 22,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  _scanStarted
                      ? _instruction
                      : 'Ready for your face scan',
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  _scanStarted
                      ? _subInstruction
                      : 'Keep your face inside the guide',
                  style:
                      const TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          if (_scanStarted &&
              !_scanCompleted)
            Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.white12,
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
              child: Text(
                '$step/${_scanSteps.length}',
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FACE GUIDE
  // ===========================================================================

  Widget _buildAnimatedFaceGuide() {
    final screenWidth =
        MediaQuery.of(context)
            .size
            .width;

    final double width =
        math.min(
      screenWidth * 0.70,
      285.0,
    ).toDouble();

    final height =
        width * 1.30;

    final active =
        _scanStarted &&
            !_scanCompleted;

    return AnimatedBuilder(
      animation:
          _guideAnimationController,
      builder:
          (
            context,
            child,
          ) {
        final pulse =
            1.0 +
                (_guideAnimationController
                        .value *
                    0.018);

        return Transform.scale(
          scale: active
              ? pulse
              : 1.0,
          child:
              Container(
            width: width,
            height: height,
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                width / 2,
              ),
              border:
                  Border.all(
                color:
                    active
                        ? const Color(
                            0xff8b7cff,
                          )
                        : Colors.white70,
                width: 3,
              ),
              boxShadow:
                  active
                      ? [
                          BoxShadow(
                            color:
                                const Color(
                              0xff6c5ce7,
                            ).withOpacity(
                              0.35,
                            ),
                            blurRadius:
                                30,
                            spreadRadius:
                                4,
                          ),
                        ]
                      : null,
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // DIRECTION HINT
  // ===========================================================================

  Widget _buildDirectionHint() {
    final step =
        _scanSteps[_currentStep];

    return Center(
      child: AnimatedSwitcher(
        duration:
            const Duration(
          milliseconds: 300,
        ),
        child: Container(
          key: ValueKey(
            _currentStep,
          ),
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          decoration:
              BoxDecoration(
            color:
                Colors.black.withOpacity(
              0.65,
            ),
            borderRadius:
                BorderRadius.circular(
              30,
            ),
          ),
          child: Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                step.icon,
                color:
                    Colors.white,
                size: 22,
              ),

              const SizedBox(
                width: 8,
              ),

              Text(
                step.title,
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CAMERA STATUS
  // ===========================================================================

  Widget _buildCameraStatus() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.black.withOpacity(
          0.68,
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration:
                BoxDecoration(
              color:
                  _scanCompleted
                      ? Colors.greenAccent
                      : _scanStarted
                          ? Colors.orangeAccent
                          : Colors.white,
              shape:
                  BoxShape.circle,
            ),
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: Text(
              _scanCompleted
                  ? 'Scan complete'
                  : _scanStarted
                      ? 'Capturing your face from different angles...'
                      : 'Good lighting helps improve detection',
              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BOTTOM BAR
  // ===========================================================================

  Widget _buildBottomBar() {
    final canCapture =
        _cameraInitialized &&
            !_capturing;

    return SafeArea(
      top: false,
      child: Container(
        color:
            Colors.black,
        padding:
            const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            // ---------------------------------------------------------------
            // Guidance
            // ---------------------------------------------------------------

            if (!_capturing)
              Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 10,
                ),
                child: Text(
                  'You will be guided through 5 quick positions',
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color:
                        Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ),

            // ---------------------------------------------------------------
            // Progress
            // ---------------------------------------------------------------

            if (_capturing)
              Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child:
                    _buildProgressIndicator(),
              ),

            // ---------------------------------------------------------------
            // Capture button
            // ---------------------------------------------------------------

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed:
                    canCapture
                        ? _startGuidedScan
                        : null,

                icon: _capturing
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons
                            .camera_alt_rounded,
                      ),

                label: Text(
                  _capturing
                      ? 'Scanning...'
                      : 'Capture & Analyse',
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xff6c5ce7,
                  ),
                  disabledBackgroundColor:
                      Colors.grey.shade800,
                  foregroundColor:
                      Colors.white,
                  minimumSize:
                      const Size(
                    double.infinity,
                    58,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PROGRESS
  // ===========================================================================

  Widget _buildProgressIndicator() {
    final progress =
        _scanStarted
            ? (_currentStep + 1) /
                _scanSteps.length
            : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
          children: [
            Text(
              'Guided face scan',
              style:
                  const TextStyle(
                color:
                    Colors.white70,
                fontSize: 12,
              ),
            ),
            Text(
              '${_currentStep + 1} / ${_scanSteps.length}',
              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 8,
        ),

        ClipRRect(
          borderRadius:
              BorderRadius.circular(
            10,
          ),
          child:
              LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor:
                Colors.white12,
            valueColor:
                const AlwaysStoppedAnimation<
                    Color>(
              Color(0xff8b7cff),
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// SCAN STEP MODEL
// ===========================================================================

class _ScanStep {
  final String title;

  final String instruction;

  final IconData icon;

  final Duration duration;

  const _ScanStep({
    required this.title,
    required this.instruction,
    required this.icon,
    required this.duration,
  });
}
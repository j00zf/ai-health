const mongoose = require("mongoose");

const cvAnalysisSchema = new mongoose.Schema(
  {
    // ========================================================================
    // USER
    // ========================================================================

    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    // ========================================================================
    // CAPTURE
    // ========================================================================

    capturedAt: {
      type: Date,
      default: Date.now,
      index: true,
    },

    source: {
      type: String,
      enum: [
        "camera",
        "image",
        "video",
      ],
      default: "camera",
    },

    modelName: {
      type: String,
      default: "mediapipe-face-landmarker",
    },

    modelVersion: {
      type: String,
      default: "1.0.0",
    },

    // Metadata about the actual camera snapshot used for analysis.
    // The raw face image is intentionally not persisted by this schema.
    captureMetadata: {
      captured: {
        type: Boolean,
        default: false,
      },
      captureMethod: {
        type: String,
        enum: ["camera_snapshot", "live_frame", "image_upload"],
        default: "camera_snapshot",
      },
      capturedAt: Date,
      rawImageStored: {
        type: Boolean,
        default: false,
      },
    },

    // ========================================================================
    // IMAGE QUALITY
    // ========================================================================

    imageQuality: {
      faceDetected: {
        type: Boolean,
        default: false,
      },

      faceConfidence: {
        type: Number,
        default: 0,
      },

      lightingScore: {
        type: Number,
        default: 0,
      },

      blurScore: {
        type: Number,
        default: 0,
      },

      faceSizeRatio: {
        type: Number,
        default: 0,
      },
    },

    // ========================================================================
    // FACE GEOMETRY
    // ========================================================================

    geometry: {
      faceAspectRatio: Number,

      eyeAspectRatioLeft: Number,

      eyeAspectRatioRight: Number,

      mouthOpeningRatio: Number,

      browEyeDistanceLeft: Number,

      browEyeDistanceRight: Number,
    },

    // ========================================================================
    // EYE FEATURES
    // ========================================================================

    eyeSignals: {
      leftEyeOpenness: Number,

      rightEyeOpenness: Number,

      blinkDetected: Boolean,

      blinkCount: Number,

      prolongedEyeClosure: Boolean,

      eyeClosureDurationMs: Number,
    },

    // ========================================================================
    // HEAD POSE
    // ========================================================================

    headPose: {
      yaw: Number,

      pitch: Number,

      roll: Number,
    },

    // ========================================================================
    // FACIAL BLENDSHAPES
    // ========================================================================

    blendshapes: {
      eyeBlinkLeft: Number,

      eyeBlinkRight: Number,

      eyeSquintLeft: Number,

      eyeSquintRight: Number,

      eyeWideLeft: Number,

      eyeWideRight: Number,

      jawOpen: Number,

      mouthSmileLeft: Number,

      mouthSmileRight: Number,

      browDownLeft: Number,

      browDownRight: Number,

      browInnerUp: Number,
    },

    // ========================================================================
    // SKIN APPEARANCE
    // ========================================================================

    skinAppearance: {
      brightnessMean: Number,

      specularHighlightRatio: Number,

      textureVariance: Number,

      visibleSkinSheenScore: Number,

      confidence: Number,
    },

    // ========================================================================
    // DERIVED VISUAL SIGNALS
    // ========================================================================

    derivedSignals: {
      visualFatigueScore: Number,

      visualFatigueConfidence: Number,

      eyeClosureScore: Number,

      alertnessScore: Number,

      visibleSkinSheenScore: Number,
    },

    // ========================================================================
    // HEALTH CONTEXT AT TIME OF ANALYSIS
    // ========================================================================

    healthContext: {
      sleepHours: Number,

      restingHeartRate: Number,

      heartRate: Number,

      steps: Number,

      bloodOxygen: Number,

      bodyTemperature: Number,

      weight: Number,
    },

    // ========================================================================
    // RAW IMAGE POLICY
    // ========================================================================

    privacy: {
      rawImageStored: {
        type: Boolean,
        default: false,
      },

      consentGiven: {
        type: Boolean,
        default: false,
      },
    },
  },

  {
    timestamps: true,
  }
);

// ============================================================================
// INDEXES
// ============================================================================

cvAnalysisSchema.index({
  userId: 1,
  capturedAt: -1,
});

module.exports =
  mongoose.models.CVAnalysis ||
  mongoose.model(
    "CVAnalysis",
    cvAnalysisSchema
  );
const mongoose = require("mongoose");

const cvAnalysisSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    capturedAt: {
      type: Date,
      default: Date.now,
      index: true,
    },

    source: {
      type: String,
      enum: ["camera", "image", "video"],
      default: "camera",
    },

    modelName: {
      type: String,
      default: "google-mlkit-face-detection",
    },

    modelVersion: {
      type: String,
      default: "1.0.0",
    },

    captureMetadata: {
      captured: { type: Boolean, default: false },
      captureMethod: {
        type: String,
        enum: ["camera_snapshot", "live_frame", "image_upload"],
        default: "camera_snapshot",
      },
      capturedAt: Date,
      rawImageStored: { type: Boolean, default: false },
      rawImageUploadedForInference: { type: Boolean, default: false },
    },

    imageQuality: {
      faceDetected: { type: Boolean, default: false },
      faceCount: { type: Number, default: 0 },
      faceConfidence: { type: Number, default: 0 },
      lightingScore: { type: Number, default: 0 },
      blurScore: { type: Number, default: 0 },
      faceSizeRatio: { type: Number, default: 0 },
    },

    geometry: {
      faceWidth: Number,
      faceHeight: Number,
      faceAreaRatio: Number,
      faceAspectRatio: Number,
      eyeAspectRatioLeft: Number,
      eyeAspectRatioRight: Number,
      mouthOpeningRatio: Number,
      browEyeDistanceLeft: Number,
      browEyeDistanceRight: Number,
    },

    eyeSignals: {
      leftEyeOpenness: Number,
      rightEyeOpenness: Number,
      averageEyeOpen: Number,
      blinkDetected: Boolean,
      blinkCount: Number,
      prolongedEyeClosure: Boolean,
      eyeClosureDurationMs: Number,
      capturedEyeClosureSamples: Number,
    },

    headPose: {
      yaw: Number,
      pitch: Number,
      roll: Number,
    },

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

    skinAppearance: {
      brightnessMean: Number,
      specularHighlightRatio: Number,
      textureVariance: Number,
      visibleSkinSheenScore: Number,
      confidence: Number,
    },

    derivedSignals: {
      visualFatigueScore: Number,
      visualFatigueConfidence: Number,
      eyeClosureScore: Number,
      alertnessScore: Number,
      visibleSkinSheenScore: Number,

      // Experimental facial stress-model fields.
      stressScore: Number,
      stressConfidence: Number,
      stressLevel: String,
    },

    stressAnalysis: {
      available: { type: Boolean, default: false },
      modelName: String,
      modelVersion: String,
      predictedClassIndex: Number,
      predictedClassName: String,
      confidence: Number,
      confidencePercent: Number,
      class0Probability: Number,
      class1Probability: Number,
      positiveClassIndex: Number,
      stressScore: Number,
      stressLevel: String,
      labelMappingVerified: { type: Boolean, default: false },
      facesDetected: Number,
      faceBoundingBox: {
        x: Number,
        y: Number,
        width: Number,
        height: Number,
      },
      modelEpoch: Number,
      status: String,
      disclaimer: String,
    },

    healthContext: {
      sleepHours: Number,
      restingHeartRate: Number,
      heartRate: Number,
      steps: Number,
      bloodOxygen: Number,
      bodyTemperature: Number,
      weight: Number,
    },

    privacy: {
      rawImageStored: { type: Boolean, default: false },
      rawImageTemporarilyProcessed: { type: Boolean, default: false },
      consentGiven: { type: Boolean, default: false },
    },

    disclaimer: String,
  },
  {
    timestamps: true,
  }
);

cvAnalysisSchema.index({
  userId: 1,
  capturedAt: -1,
});

module.exports =
  mongoose.models.CVAnalysis ||
  mongoose.model("CVAnalysis", cvAnalysisSchema);

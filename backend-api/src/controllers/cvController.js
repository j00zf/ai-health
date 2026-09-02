const axios = require("axios");
const FormData = require("form-data");

const CVAnalysis = require("../models/CVAnalysis");
const HealthRecord = require("../models/HealthRecord");

const PY_CV_URL = (process.env.PY_CV_URL || "http://127.0.0.1:8000").replace(/\/$/, "");
const STRESS_POSITIVE_CLASS_INDEX = Number(
  process.env.STRESS_POSITIVE_CLASS_INDEX ?? 1
);
const STRESS_LABEL_MAPPING_VERIFIED =
  String(process.env.STRESS_LABEL_MAPPING_VERIFIED || "false").toLowerCase() ===
  "true";

function numberOrNull(value) {
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

function average(values) {
  const valid = values.filter(
    (value) => typeof value === "number" && !Number.isNaN(value)
  );
  if (!valid.length) return null;
  return valid.reduce((sum, value) => sum + value, 0) / valid.length;
}

function stressLevel(score, verified = STRESS_LABEL_MAPPING_VERIFIED) {
  if (!verified || typeof score !== "number") return "unverified";
  if (score < 0.4) return "low";
  if (score < 0.7) return "moderate";
  return "elevated";
}

function parseFeatures(value) {
  if (!value) return {};
  if (typeof value === "object") return value;
  try {
    return JSON.parse(value);
  } catch (_) {
    throw new Error("Invalid JSON in the features field");
  }
}

async function getLatestHealthContext(userId) {
  const latestHealth = await HealthRecord.findOne({ userId })
    .sort({ date: -1 })
    .lean();

  if (!latestHealth) return {};

  return {
    sleepHours: latestHealth.sleepHours,
    restingHeartRate: latestHealth.restingHeartRate,
    heartRate: latestHealth.heartRate,
    steps: latestHealth.steps,
    bloodOxygen: latestHealth.bloodOxygen,
    bodyTemperature: latestHealth.bodyTemperature,
    weight: latestHealth.weight,
  };
}

function buildStressAnalysis(pyResult) {
  if (!pyResult?.success) {
    return {
      available: false,
      status: "prediction_unavailable",
      labelMappingVerified: STRESS_LABEL_MAPPING_VERIFIED,
      disclaimer:
        "Facial analysis is experimental supporting context and is not a medical or psychological diagnosis.",
    };
  }

  const class0 = numberOrNull(pyResult?.probabilities?.class_0);
  const class1 = numberOrNull(pyResult?.probabilities?.class_1);

  const positiveProbability =
    STRESS_POSITIVE_CLASS_INDEX === 0 ? class0 : class1;

  const score =
    typeof positiveProbability === "number"
      ? Math.max(0, Math.min(1, positiveProbability))
      : null;

  const confidence = numberOrNull(pyResult?.prediction?.confidence);

  return {
    available: true,
    modelName: pyResult?.model?.name || "Facial Stress CNN",
    modelVersion: pyResult?.model?.version || "V1",
    predictedClassIndex: pyResult?.prediction?.class_index,
    predictedClassName: pyResult?.prediction?.class_name,
    confidence,
    confidencePercent:
      numberOrNull(pyResult?.prediction?.confidence_percent) ??
      (typeof confidence === "number" ? confidence * 100 : null),
    class0Probability: class0,
    class1Probability: class1,
    positiveClassIndex: STRESS_POSITIVE_CLASS_INDEX,
    stressScore: score,
    stressLevel: stressLevel(score),
    labelMappingVerified: STRESS_LABEL_MAPPING_VERIFIED,
    facesDetected: pyResult?.face_detection?.faces_detected ?? null,
    faceBoundingBox: pyResult?.face_detection?.bounding_box || undefined,
    modelEpoch: pyResult?.model_epoch ?? null,
    status: STRESS_LABEL_MAPPING_VERIFIED
      ? "experimental"
      : "experimental_unverified_label_mapping",
    disclaimer:
      "This is an experimental visual estimate. Facial appearance alone cannot establish psychological stress or a diagnosis.",
  };
}

function buildChatbotContext(record) {
  const stress = record?.stressAnalysis || {};
  const derived = record?.derivedSignals || {};
  const health = record?.healthContext || {};

  return {
    source: "computer_vision",
    capturedAt: record?.capturedAt || null,
    facialAnalysis: {
      available: stress.available === true,
      predictedClass: stress.predictedClassName || null,
      confidence: stress.confidence ?? null,
      stressScore: stress.stressScore ?? null,
      stressLevel: stress.stressLevel || "unavailable",
      labelMappingVerified: stress.labelMappingVerified === true,
      class0Probability: stress.class0Probability ?? null,
      class1Probability: stress.class1Probability ?? null,
    },
    visualSignals: {
      visualFatigueScore: derived.visualFatigueScore ?? null,
      alertnessScore: derived.alertnessScore ?? null,
      eyeClosureScore: derived.eyeClosureScore ?? null,
    },
    healthContext: {
      sleepHours: health.sleepHours ?? null,
      restingHeartRate: health.restingHeartRate ?? null,
      heartRate: health.heartRate ?? null,
      steps: health.steps ?? null,
      bloodOxygen: health.bloodOxygen ?? null,
    },
    chatbotGuidance: {
      priority: "Use the user's own words as the primary source of truth.",
      use:
        "Use facial/CV values only as supporting context and acknowledge uncertainty, especially when confidence is low or label mapping is unverified.",
      avoid:
        "Do not diagnose stress, anxiety, depression, or any medical/psychological condition from facial analysis.",
    },
  };
}

async function createRecord({ userId, features, stressAnalysis, rawImageProcessed }) {
  if (!features?.imageQuality?.faceDetected) {
    const error = new Error("No face detected");
    error.statusCode = 400;
    throw error;
  }

  const healthContext = await getLatestHealthContext(userId);

  const derivedSignals = {
    ...(features.derivedSignals || {}),
  };

  if (stressAnalysis?.available) {
    derivedSignals.stressScore = stressAnalysis.stressScore;
    derivedSignals.stressConfidence = stressAnalysis.confidence;
    derivedSignals.stressLevel = stressAnalysis.stressLevel;
  }

  const record = await CVAnalysis.create({
    userId,
    capturedAt: features.capturedAt ? new Date(features.capturedAt) : new Date(),
    source: features.source || "camera",
    modelName: features.modelName || "google-mlkit-face-detection",
    modelVersion: features.modelVersion || "1.0.0",
    imageQuality: features.imageQuality,
    geometry: features.geometry,
    eyeSignals: features.eyeSignals,
    headPose: features.headPose,
    blendshapes: features.blendshapes,
    skinAppearance: features.skinAppearance,
    derivedSignals,
    stressAnalysis,
    captureMetadata: {
      captured: features.capture?.captured === true,
      captureMethod: features.capture?.captureMethod || "camera_snapshot",
      capturedAt: features.capture?.capturedAt
        ? new Date(features.capture.capturedAt)
        : new Date(),
      rawImageStored: false,
      rawImageUploadedForInference: rawImageProcessed === true,
    },
    privacy: {
      rawImageStored: false,
      rawImageTemporarilyProcessed: rawImageProcessed === true,
      consentGiven: features.privacy?.consentGiven === true,
    },
    healthContext,
    disclaimer:
      features.disclaimer ||
      "Computer-vision and facial-model outputs are non-clinical indicators and are not a diagnosis.",
  });

  return record;
}

// JSON-only legacy/current endpoint. Keeps your existing feature-only flow working.
exports.analyze = async (req, res) => {
  try {
    const features = req.body || {};
    const record = await createRecord({
      userId: req.user.id,
      features,
      stressAnalysis: {
        available: false,
        status: "image_not_supplied",
        labelMappingVerified: STRESS_LABEL_MAPPING_VERIFIED,
        disclaimer:
          "No image was supplied to the server-side facial stress model for this record.",
      },
      rawImageProcessed: false,
    });

    return res.status(201).json({
      success: true,
      message: "CV analysis stored successfully",
      analysis: record,
      chatbotContext: buildChatbotContext(record.toObject()),
    });
  } catch (error) {
    console.error("[CV] Analysis error:", error);
    return res.status(error.statusCode || 500).json({
      success: false,
      message: error.message || "CV analysis failed",
    });
  }
};

// Multipart endpoint used by the Flutter guided camera flow.
// fields: features=<JSON string>, file=<JPEG/PNG>
exports.analyzeWithImage = async (req, res) => {
  try {
    if (!req.file?.buffer) {
      return res.status(400).json({
        success: false,
        message: "Face image is required",
      });
    }

    const features = parseFeatures(req.body.features);

    if (!features?.imageQuality?.faceDetected) {
      return res.status(400).json({
        success: false,
        message: "No face detected in the local CV scan",
      });
    }

    const form = new FormData();
    form.append("file", req.file.buffer, {
      filename: req.file.originalname || "face.jpg",
      contentType: req.file.mimetype || "image/jpeg",
    });

    const pythonResponse = await axios.post(
      `${PY_CV_URL}/py-cv/predict`,
      form,
      {
        headers: form.getHeaders(),
        timeout: 30000,
        maxContentLength: 15 * 1024 * 1024,
        maxBodyLength: 15 * 1024 * 1024,
      }
    );

    const stressAnalysis = buildStressAnalysis(pythonResponse.data);

    const record = await createRecord({
      userId: req.user.id,
      features,
      stressAnalysis,
      rawImageProcessed: true,
    });

    return res.status(201).json({
      success: true,
      message: "CV + facial stress analysis stored successfully",
      analysis: record,
      stressAnalysis,
      chatbotContext: buildChatbotContext(record.toObject()),
    });
  } catch (error) {
    console.error(
      "[CV] Analyze-with-image error:",
      error?.response?.data || error
    );

    const pythonMessage =
      error?.response?.data?.detail ||
      error?.response?.data?.message ||
      null;

    return res.status(error.statusCode || 500).json({
      success: false,
      message:
        pythonMessage || error.message || "CV + facial stress analysis failed",
    });
  }
};

exports.getLatest = async (req, res) => {
  try {
    const record = await CVAnalysis.findOne({ userId: req.user.id })
      .sort({ capturedAt: -1 })
      .lean();

    if (!record) {
      return res.status(404).json({ success: false, message: "No CV analysis found" });
    }

    return res.json({
      success: true,
      analysis: record,
      chatbotContext: buildChatbotContext(record),
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

exports.getLatestChatContext = async (req, res) => {
  try {
    const record = await CVAnalysis.findOne({ userId: req.user.id })
      .sort({ capturedAt: -1 })
      .lean();

    if (!record) {
      return res.status(404).json({
        success: false,
        message: "No CV analysis found",
      });
    }

    return res.json({
      success: true,
      context: buildChatbotContext(record),
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

exports.getHistory = async (req, res) => {
  try {
    const limit = Math.min(Number(req.query.limit) || 30, 365);
    const records = await CVAnalysis.find({ userId: req.user.id })
      .sort({ capturedAt: -1 })
      .limit(limit)
      .lean();

    return res.json({ success: true, count: records.length, analyses: records });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

exports.getById = async (req, res) => {
  try {
    const record = await CVAnalysis.findOne({
      _id: req.params.id,
      userId: req.user.id,
    }).lean();

    if (!record) {
      return res.status(404).json({ success: false, message: "CV analysis not found" });
    }

    return res.json({
      success: true,
      analysis: record,
      chatbotContext: buildChatbotContext(record),
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

exports.getTrends = async (req, res) => {
  try {
    const limit = Math.min(Number(req.query.limit) || 30, 365);
    const records = await CVAnalysis.find({ userId: req.user.id })
      .sort({ capturedAt: 1 })
      .limit(limit)
      .lean();

    const trends = records.map((record) => ({
      id: record._id,
      capturedAt: record.capturedAt,
      stress: record.stressAnalysis?.stressScore ?? record.derivedSignals?.stressScore ?? null,
      stressConfidence:
        record.stressAnalysis?.confidence ?? record.derivedSignals?.stressConfidence ?? null,
      stressLevel:
        record.stressAnalysis?.stressLevel ?? record.derivedSignals?.stressLevel ?? null,
      stressLabelMappingVerified:
        record.stressAnalysis?.labelMappingVerified === true,
      fatigue: record.derivedSignals?.visualFatigueScore ?? null,
      alertness: record.derivedSignals?.alertnessScore ?? null,
      eyeClosure: record.derivedSignals?.eyeClosureScore ?? null,
      skinSheen: record.skinAppearance?.visibleSkinSheenScore ?? null,
      blinkCount: record.eyeSignals?.blinkCount ?? null,
      eyeOpennessLeft: record.eyeSignals?.leftEyeOpenness ?? null,
      eyeOpennessRight: record.eyeSignals?.rightEyeOpenness ?? null,
    }));

    return res.json({ success: true, count: trends.length, trends });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

exports.getSummary = async (req, res) => {
  try {
    const records = await CVAnalysis.find({ userId: req.user.id })
      .sort({ capturedAt: -1 })
      .limit(30)
      .lean();

    if (!records.length) {
      return res.json({
        success: true,
        summary: {
          analysisCount: 0,
          averageStress: null,
          averageStressConfidence: null,
          averageFatigue: null,
          averageAlertness: null,
          averageEyeClosure: null,
          averageSkinSheen: null,
          latest: null,
        },
      });
    }

    return res.json({
      success: true,
      summary: {
        analysisCount: records.length,
        averageStress: average(
          records.map(
            (r) => r.stressAnalysis?.stressScore ?? r.derivedSignals?.stressScore
          )
        ),
        averageStressConfidence: average(
          records.map(
            (r) => r.stressAnalysis?.confidence ?? r.derivedSignals?.stressConfidence
          )
        ),
        averageFatigue: average(
          records.map((r) => r.derivedSignals?.visualFatigueScore)
        ),
        averageAlertness: average(
          records.map((r) => r.derivedSignals?.alertnessScore)
        ),
        averageEyeClosure: average(
          records.map((r) => r.derivedSignals?.eyeClosureScore)
        ),
        averageSkinSheen: average(
          records.map((r) => r.skinAppearance?.visibleSkinSheenScore)
        ),
        latest: records[0],
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

exports.delete = async (req, res) => {
  try {
    const result = await CVAnalysis.findOneAndDelete({
      _id: req.params.id,
      userId: req.user.id,
    });

    if (!result) {
      return res.status(404).json({ success: false, message: "CV analysis not found" });
    }

    return res.json({ success: true, message: "CV analysis deleted" });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

exports.buildChatbotContext = buildChatbotContext;

const CVAnalysis = require("../models/CVAnalysis");

function buildContext(record) {
  if (!record) return null;

  const stress = record.stressAnalysis || {};
  const derived = record.derivedSignals || {};
  const health = record.healthContext || {};

  return {
    source: "computer_vision",
    capturedAt: record.capturedAt || null,
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
    instruction:
      "Use the user's own text as the primary source of truth. Treat facial/CV " +
      "outputs only as uncertain supporting context. Never diagnose stress, anxiety, " +
      "depression, or another medical/psychological condition from facial appearance.",
  };
}

async function getLatestCvChatContext(userId) {
  const record = await CVAnalysis.findOne({ userId })
    .sort({ capturedAt: -1 })
    .lean();

  return buildContext(record);
}

module.exports = {
  buildContext,
  getLatestCvChatContext,
};

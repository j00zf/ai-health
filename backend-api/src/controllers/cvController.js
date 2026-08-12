const CVAnalysis = require("../models/CVAnalysis");
const HealthRecord = require("../models/HealthRecord");

// ============================================================================
// CREATE CV ANALYSIS
// ============================================================================

exports.analyze = async (req, res) => {
  try {
    const {
      capturedAt,
      source,
      modelName,
      modelVersion,
      imageQuality,
      geometry,
      eyeSignals,
      headPose,
      blendshapes,
      skinAppearance,
      derivedSignals,
    } = req.body;

    if (!imageQuality?.faceDetected) {
      return res.status(400).json({
        success: false,
        message: "No face detected",
      });
    }

    // ------------------------------------------------------------------------
    // Get latest health data for context
    // ------------------------------------------------------------------------

    const latestHealth =
      await HealthRecord.findOne({
        userId: req.user.id,
      })
        .sort({
          date: -1,
        })
        .lean();

    // ------------------------------------------------------------------------
    // Create CV record
    // ------------------------------------------------------------------------

    const record =
      await CVAnalysis.create({
        userId: req.user.id,

        capturedAt:
          capturedAt
            ? new Date(capturedAt)
            : new Date(),

        source:
          source || "camera",

        modelName:
          modelName ||
          "mediapipe-face-landmarker",

        modelVersion:
          modelVersion || "1.0.0",

        imageQuality,

        geometry,

        eyeSignals,

        headPose,

        blendshapes,

        skinAppearance,

        derivedSignals,

        healthContext:
          latestHealth
            ? {
                sleepHours:
                  latestHealth.sleepHours,

                restingHeartRate:
                  latestHealth.restingHeartRate,

                heartRate:
                  latestHealth.heartRate,

                steps:
                  latestHealth.steps,

                bloodOxygen:
                  latestHealth.bloodOxygen,

                bodyTemperature:
                  latestHealth.bodyTemperature,

                weight:
                  latestHealth.weight,
              }
            : {},
      });

    return res.status(201).json({
      success: true,

      message:
        "CV analysis stored successfully",

      analysis: record,
    });
  } catch (error) {
    console.error(
      "[CV] Analysis error:",
      error
    );

    return res.status(500).json({
      success: false,
      message:
        error.message ||
        "CV analysis failed",
    });
  }
};

// ============================================================================
// GET LATEST
// ============================================================================

exports.getLatest = async (
  req,
  res
) => {
  try {
    const record =
      await CVAnalysis.findOne({
        userId: req.user.id,
      })
        .sort({
          capturedAt: -1,
        })
        .lean();

    if (!record) {
      return res.status(404).json({
        success: false,
        message:
          "No CV analysis found",
      });
    }

    return res.json({
      success: true,
      analysis: record,
    });
  } catch (error) {
    console.error(
      "[CV] Latest error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ============================================================================
// GET HISTORY
// ============================================================================

exports.getHistory = async (
  req,
  res
) => {
  try {
    const limit = Math.min(
      Number(req.query.limit) || 30,
      365
    );

    const records =
      await CVAnalysis.find({
        userId: req.user.id,
      })
        .sort({
          capturedAt: -1,
        })
        .limit(limit)
        .lean();

    return res.json({
      success: true,
      count: records.length,
      analyses: records,
    });
  } catch (error) {
    console.error(
      "[CV] History error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ============================================================================
// GET SINGLE
// ============================================================================

exports.getById = async (
  req,
  res
) => {
  try {
    const record =
      await CVAnalysis.findOne({
        _id: req.params.id,

        userId: req.user.id,
      }).lean();

    if (!record) {
      return res.status(404).json({
        success: false,
        message:
          "CV analysis not found",
      });
    }

    return res.json({
      success: true,
      analysis: record,
    });
  } catch (error) {
    console.error(
      "[CV] Get analysis error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
// ============================================================================
// TRENDS
// ============================================================================

exports.getTrends = async (
  req,
  res
) => {
  try {
    const limit = Math.min(
      Number(req.query.limit) || 30,
      365
    );

    const records =
      await CVAnalysis.find({
        userId: req.user.id,
      })
        .sort({
          capturedAt: 1,
        })
        .limit(limit)
        .lean();

    const trends =
      records.map(
        (record) => ({
          id: record._id,

          capturedAt:
            record.capturedAt,

          fatigue:
            record.derivedSignals
              ?.visualFatigueScore ??
            null,

          alertness:
            record.derivedSignals
              ?.alertnessScore ??
            null,

          eyeClosure:
            record.derivedSignals
              ?.eyeClosureScore ??
            null,

          skinSheen:
            record.skinAppearance
              ?.visibleSkinSheenScore ??
            null,

          blinkCount:
            record.eyeSignals
              ?.blinkCount ??
            null,

          eyeOpennessLeft:
            record.eyeSignals
              ?.leftEyeOpenness ??
            null,

          eyeOpennessRight:
            record.eyeSignals
              ?.rightEyeOpenness ??
            null,
        })
      );

    return res.json({
      success: true,

      count: trends.length,

      trends,
    });
  } catch (error) {
    console.error(
      "[CV] Trends error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
// ============================================================================
// SUMMARY
// ============================================================================

exports.getSummary = async (
  req,
  res
) => {
  try {
    const records =
      await CVAnalysis.find({
        userId: req.user.id,
      })
        .sort({
          capturedAt: -1,
        })
        .limit(30)
        .lean();

    if (!records.length) {
      return res.json({
        success: true,

        summary: {
          analysisCount: 0,
          averageFatigue: null,
          averageAlertness: null,
          averageEyeClosure: null,
          averageSkinSheen: null,
        },
      });
    }

    const average = (
      values
    ) => {
      const valid =
        values.filter(
          (v) =>
            typeof v ===
              "number" &&
            !Number.isNaN(v)
        );

      if (!valid.length) {
        return null;
      }

      return (
        valid.reduce(
          (a, b) => a + b,
          0
        ) / valid.length
      );
    };

    const fatigue =
      records.map(
        (r) =>
          r.derivedSignals
            ?.visualFatigueScore
      );

    const alertness =
      records.map(
        (r) =>
          r.derivedSignals
            ?.alertnessScore
      );

    const eyeClosure =
      records.map(
        (r) =>
          r.derivedSignals
            ?.eyeClosureScore
      );

    const skinSheen =
      records.map(
        (r) =>
          r.skinAppearance
            ?.visibleSkinSheenScore
      );

    return res.json({
      success: true,

      summary: {
        analysisCount:
          records.length,

        averageFatigue:
          average(fatigue),

        averageAlertness:
          average(alertness),

        averageEyeClosure:
          average(eyeClosure),

        averageSkinSheen:
          average(skinSheen),

        latest:
          records[0],
      },
    });
  } catch (error) {
    console.error(
      "[CV] Summary error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ============================================================================
// DELETE
// ============================================================================

exports.delete = async (
  req,
  res
) => {
  try {
    const result =
      await CVAnalysis.findOneAndDelete({
        _id: req.params.id,

        userId: req.user.id,
      });

    if (!result) {
      return res.status(404).json({
        success: false,
        message:
          "CV analysis not found",
      });
    }

    return res.json({
      success: true,
      message:
        "CV analysis deleted",
    });
  } catch (error) {
    console.error(
      "[CV] Delete error:",
      error
    );

    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
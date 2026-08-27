const axios = require("axios");

const HealthRecord =
    require("../models/HealthRecord");

const MLHealthAnalysis =
    require("../models/mlHealthAnalysis");

const {
    normalizeHealthRecords,
    extractLatestDimensions,
} = require(
    "../utils/mlHealthDataHelper"
);


const ML_API_URL =
    process.env.ML_API_URL ||
    "http://127.0.0.1:8000";


function getUserId(req) {
    return (
        req.user?._id ||
        req.user?.id ||
        req.userId
    );
}


function buildProfile(userProfile = {}) {
    return {
        age:
            userProfile.age ??
            userProfile.age_years ??
            null,

        sex:
            userProfile.sex ??
            null,

        height_cm:
            userProfile.height_cm ??
            userProfile.height ??
            null,

        weight_kg:
            userProfile.weight_kg ??
            userProfile.weight ??
            null,

        bmi:
            userProfile.bmi ??
            null,

        waist_cm:
            userProfile.waist_cm ??
            userProfile.waist ??
            null,

        heart_rate:
            userProfile.heart_rate ??
            userProfile.heartRate ??
            null,

        activity_minutes:
            userProfile.activity_minutes ??
            userProfile.activityMinutes ??
            null,

        sleep_hours:
            userProfile.sleep_hours ??
            userProfile.sleepHours ??
            null,

        smoking:
            userProfile.smoking ??
            userProfile.smoke ??
            0,

        alcohol:
            userProfile.alcohol ??
            0,
    };
}


function serializeAnalysis(analysis) {
    return {
        id: analysis._id,

        analyzedAt:
            analysis.analyzedAt,

        sourceRecordDate:
            analysis.sourceRecordDate,

        recordsAnalyzed:
            analysis.recordsAnalyzed,

        scores:
            analysis.scores,

        dimensions:
            analysis.dimensions,

        forecast:
            analysis.forecast,

        dataQuality:
            analysis.dataQuality,

        missingData:
            analysis.missingData,

        missingDataCount:
            analysis.missingDataCount,

        modelVersion:
            analysis.modelVersion,
    };
}


// ============================================================
// ANALYZE USER
// ============================================================

exports.mlAnalyzeHealth = async (
    req,
    res
) => {
    try {
        const userId =
            getUserId(req);

        if (!userId) {
            return res.status(401).json({
                success: false,
                message:
                    "User authentication required.",
            });
        }

        const {
            profile = {},
            health_records,
        } = req.body;


        // ----------------------------------------------------
        // LOAD HEALTH RECORDS
        // ----------------------------------------------------

        let healthRecords =
            health_records;

        if (
            !Array.isArray(healthRecords) ||
            !healthRecords.length
        ) {
            healthRecords =
                await HealthRecord.find({
                    user: userId,
                })
                    .sort({
                        date: -1,
                    })
                    .limit(30)
                    .lean();
        }


        if (!healthRecords.length) {
            return res.status(400).json({
                success: false,
                message:
                    "No health records available for ML analysis.",
            });
        }


        // Reverse because database query is newest first
        healthRecords =
            healthRecords.reverse();


        // ----------------------------------------------------
        // NORMALIZE MISSING VALUES
        // ----------------------------------------------------

        const normalization =
            normalizeHealthRecords(
                healthRecords
            );

        const normalizedRecords =
            normalization.records;

        const missingData =
            normalization.missingData;


        // ----------------------------------------------------
        // LATEST RECORD
        // ----------------------------------------------------

        const latestRecord =
            normalizedRecords[
                normalizedRecords.length - 1
            ];


        // ----------------------------------------------------
        // PROFILE
        // ----------------------------------------------------

        const mlProfile =
            buildProfile(profile);


        // ----------------------------------------------------
        // CALL PYTHON ML API
        // ----------------------------------------------------

        const mlResponse =
            await axios.post(
                `${ML_API_URL}/api/v1/analyze`,
                {
                    profile:
                        mlProfile,

                    health_records:
                        normalizedRecords,
                },
                {
                    timeout: 30000,
                    headers: {
                        "Content-Type":
                            "application/json",
                    },
                }
            );


        const mlResult =
            mlResponse.data?.data ||
            mlResponse.data;


        // ----------------------------------------------------
        // EXTRACT RESULTS
        // ----------------------------------------------------

        const scores =
            mlResult.scores || {};

        const dimensions =
            extractLatestDimensions(
                mlResult
            );

        const forecast =
            mlResult.forecast || {};

        const dataQuality =
            mlResult.dataQuality ||
            mlResult.wellness
                ?.dataQuality ||
            {};


        // ----------------------------------------------------
        // SAVE ANALYSIS
        // ----------------------------------------------------

        const savedAnalysis =
            await MLHealthAnalysis.create({
                user:
                    userId,

                analyzedAt:
                    new Date(),

                sourceRecordDate:
                    latestRecord.date ||
                    null,

                recordsAnalyzed:
                    normalizedRecords.length,

                scores,

                dimensions,

                forecast,

                dataQuality,

                missingData:
                    missingData.map(
                        (item) => ({
                            field:
                                item.field,

                            message:
                                item.message,

                            fallbackValue:
                                item.fallbackValue,
                        })
                    ),

                missingDataCount:
                    missingData.length,

                mlResponse:
                    mlResult,

                modelVersion:
                    mlResult.modelVersion ||
                    "v2-deployment",
            });


        return res.status(200).json({
            success: true,

            source:
                "pulse-ai",

            message:
                "ML health analysis completed successfully.",

            data: {
                ...mlResult,

                latestHealthRecord:
                    latestRecord,

                missingData,

                missingDataCount:
                    missingData.length,

                savedAnalysis:
                    serializeAnalysis(
                        savedAnalysis
                    ),
            },
        });
    } catch (error) {
        console.error(
            "ML HEALTH ANALYSIS ERROR:",
            error.response?.data ||
            error.message
        );

        return res.status(500).json({
            success: false,

            message:
                "Unable to complete ML health analysis.",

            error:
                error.response?.data ||
                error.message,
        });
    }
};


// ============================================================
// CURRENT ML HEALTH DASHBOARD
// ============================================================

exports.mlGetDashboard = async (
    req,
    res
) => {
    try {
        const userId =
            getUserId(req);

        if (!userId) {
            return res.status(401).json({
                success: false,
                message:
                    "User authentication required.",
            });
        }


        const latestAnalysis =
            await MLHealthAnalysis.findOne({
                user: userId,
            })
                .sort({
                    analyzedAt: -1,
                })
                .lean();


        const latestHealthRecord =
            await HealthRecord.findOne({
                user: userId,
            })
                .sort({
                    date: -1,
                })
                .lean();


        if (!latestAnalysis) {
            return res.status(404).json({
                success: false,

                message:
                    "No ML health analysis available. Run analysis first.",

                data: {
                    latestHealthRecord:
                        latestHealthRecord ||
                        null,

                    analysis:
                        null,
                },
            });
        }


        return res.status(200).json({
            success: true,

            data: {
                analysis:
                    latestAnalysis,

                latestHealthRecord:
                    latestHealthRecord ||
                    null,

                notifications:
                    latestAnalysis.missingData ||
                    [],
            },
        });
    } catch (error) {
        console.error(
            "ML DASHBOARD ERROR:",
            error
        );

        return res.status(500).json({
            success: false,
            message:
                "Unable to load ML dashboard.",
        });
    }
};


// ============================================================
// ML HEALTH HISTORY
// ============================================================

exports.mlGetHistory = async (
    req,
    res
) => {
    try {
        const userId =
            getUserId(req);

        const limit = Math.min(
            Number(req.query.limit) || 100,
            365
        );


        const history =
            await MLHealthAnalysis.find({
                user: userId,
            })
                .sort({
                    analyzedAt: 1,
                })
                .limit(limit)
                .lean();


        const formattedHistory =
            history.map(
                (item) => ({
                    id:
                        item._id,

                    date:
                        item.analyzedAt,

                    scores:
                        item.scores,

                    dimensions:
                        item.dimensions,

                    forecast:
                        item.forecast,

                    dataQuality:
                        item.dataQuality,

                    missingDataCount:
                        item.missingDataCount ||
                        0,
                })
            );


        return res.status(200).json({
            success: true,

            count:
                formattedHistory.length,

            data:
                formattedHistory,
        });
    } catch (error) {
        console.error(
            "ML HISTORY ERROR:",
            error
        );

        return res.status(500).json({
            success: false,
            message:
                "Unable to load ML health history.",
        });
    }
};


// ============================================================
// ML HEALTH IMPROVEMENT
// ============================================================

exports.mlGetImprovement = async (
    req,
    res
) => {
    try {
        const userId =
            getUserId(req);

        const analyses =
            await MLHealthAnalysis.find({
                user: userId,
            })
                .sort({
                    analyzedAt: 1,
                })
                .lean();


        if (!analyses.length) {
            return res.status(200).json({
                success: true,

                data: {
                    summary: null,
                    history: [],
                },
            });
        }


        const first =
            analyses[0];

        const latest =
            analyses[
                analyses.length - 1
            ];


        function difference(
            latestValue,
            firstValue
        ) {
            if (
                typeof latestValue !==
                    "number" ||
                typeof firstValue !==
                    "number"
            ) {
                return null;
            }

            return Number(
                (
                    latestValue -
                    firstValue
                ).toFixed(2)
            );
        }


        const summary = {
            overallWellbeing:
                difference(
                    latest.scores
                        ?.overallWellbeingScore,
                    first.scores
                        ?.overallWellbeingScore
                ),

            heartHealth:
                difference(
                    latest.scores
                        ?.heartHealthScore,
                    first.scores
                        ?.heartHealthScore
                ),

            health:
                difference(
                    latest.scores
                        ?.healthScore,
                    first.scores
                        ?.healthScore
                ),

            personalWellness:
                difference(
                    latest.scores
                        ?.personalWellnessScore,
                    first.scores
                        ?.personalWellnessScore
                ),
        };


        const history =
            analyses.map(
                (item) => ({
                    date:
                        item.analyzedAt,

                    overallWellbeingScore:
                        item.scores
                            ?.overallWellbeingScore ??
                        null,

                    heartHealthScore:
                        item.scores
                            ?.heartHealthScore ??
                        null,

                    healthScore:
                        item.scores
                            ?.healthScore ??
                        null,

                    personalWellnessScore:
                        item.scores
                            ?.personalWellnessScore ??
                        null,

                    activity:
                        item.dimensions
                            ?.activity ??
                        null,

                    sleep:
                        item.dimensions
                            ?.sleep ??
                        null,

                    recovery:
                        item.dimensions
                            ?.recovery ??
                        null,
                })
            );


        return res.status(200).json({
            success: true,

            data: {
                totalAnalyses:
                    analyses.length,

                firstAnalysisDate:
                    first.analyzedAt,

                latestAnalysisDate:
                    latest.analyzedAt,

                summary,

                history,
            },
        });
    } catch (error) {
        console.error(
            "ML IMPROVEMENT ERROR:",
            error
        );

        return res.status(500).json({
            success: false,
            message:
                "Unable to calculate improvements.",
        });
    }
};


// ============================================================
// LATEST ANALYSIS
// ============================================================

exports.mlGetLatestAnalysis = async (
    req,
    res
) => {
    try {
        const userId =
            getUserId(req);

        const analysis =
            await MLHealthAnalysis.findOne({
                user: userId,
            })
                .sort({
                    analyzedAt: -1,
                })
                .lean();


        return res.status(200).json({
            success: true,
            data: analysis || null,
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message:
                "Unable to load latest analysis.",
        });
    }
};
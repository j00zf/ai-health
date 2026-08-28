const HealthRecord = require("../models/HealthRecord");

const MLHealthAnalysis = require(
"../models/mlHealthAnalysis"
);

const {
normalizeHealthRecords,
extractLatestDimensions,
} = require(
"../utils/mlHealthDataHelper"
);

const {
analyzeWithPulseAI,
} = require(
"../services/pulseAiService"
);

// ============================================================
// HELPERS
// ============================================================

function getUserId(req) {
return (
req.user?._id ||
req.user?.id ||
req.userId
);
}

// ============================================================
// BUILD ML PROFILE
// ============================================================

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

// ============================================================
// NORMALIZE DATABASE RECORD FOR ML
//
// Converts HealthRecord schema fields to Pulse AI fields.
// ============================================================

function mapDatabaseRecordToMlRecord(record = {}) {
return {
date:
record.date ?? null,


    steps:
        record.steps ?? null,

    activeHours:
        record.activeHours ?? null,

    activeZoneMinutes:
        record.activeZoneMinutes ?? null,

    heartRate:
        record.heartRate ?? null,

    restingHeartRate:
        record.restingHeartRate ?? null,

    // Database uses sleepHours.
    // ML uses sleep.
    sleep:
        record.sleep ??
        record.sleepHours ??
        null,

    weight:
        record.weight ?? null,

    bmi:
        record.bmi ?? null,

    // Database uses bloodOxygen.
    // ML uses oxygenSaturation.
    oxygenSaturation:
        record.oxygenSaturation ??
        record.bloodOxygen ??
        null,

    calories:
        record.calories ?? null,

    // Database uses distanceWalked.
    // ML uses distance.
    distance:
        record.distance ??
        record.distanceWalked ??
        null,
};


}

// ============================================================
// SERIALIZE ANALYSIS
// ============================================================

function serializeAnalysis(analysis) {
if (!analysis) {
return null;
}


return {
    id:
        analysis._id,

    analyzedAt:
        analysis.analyzedAt,

    sourceRecordDate:
        analysis.sourceRecordDate,

    recordsAnalyzed:
        analysis.recordsAnalyzed,

    scores:
        analysis.scores || {},

    dimensions:
        analysis.dimensions || {},

    forecast:
        analysis.forecast || {},

    dataQuality:
        analysis.dataQuality || {},

    missingData:
        analysis.missingData || [],

    missingDataCount:
        analysis.missingDataCount || 0,

    modelVersion:
        analysis.modelVersion ||
        null,
};


}

// ============================================================
// GET LATEST HEALTH RECORD
// ============================================================

exports.mlGetLatestHealthRecord = async (
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

    const latestRecord =
        await HealthRecord.findOne({
            userId: userId,
        })
            .sort({
                date: -1,
                syncedAt: -1,
            })
            .lean();

    return res.status(200).json({
        success: true,

        data: {
            latestRecord:
                latestRecord || null,

            hasHealthRecords:
                latestRecord !== null,
        },
    });
} catch (error) {
    console.error(
        "ML LATEST HEALTH RECORD ERROR:",
        error
    );

    return res.status(500).json({
        success: false,
        message:
            "Unable to load the latest health record.",
        error:
            error.message,
    });
}


};

// ============================================================
// RUN ML HEALTH ANALYSIS
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
    } = req.body || {};


    // --------------------------------------------------------
    // ALWAYS LOAD LATEST RECORDS FROM DATABASE
    //
    // Flutter does NOT send health records.
    // Database is the source of truth.
    // --------------------------------------------------------

    let healthRecords =
        await HealthRecord.find({
            userId: userId,
        })
            .sort({
                date: -1,
                syncedAt: -1,
            })
            .limit(30)
            .lean();


    if (!healthRecords.length) {
        return res.status(400).json({
            success: false,
            message:
                "No health records available for ML analysis.",
        });
    }


    // Database result is newest → oldest.
    // ML receives oldest → newest.
    healthRecords =
        [...healthRecords]
            .reverse();


    // --------------------------------------------------------
    // MAP DATABASE SCHEMA → ML SCHEMA
    // --------------------------------------------------------

    const mlRecords =
        healthRecords.map(
            mapDatabaseRecordToMlRecord
        );


    // --------------------------------------------------------
    // NORMALIZE MISSING VALUES
    // --------------------------------------------------------

    const normalization =
        normalizeHealthRecords(
            mlRecords
        );

    const normalizedRecords =
        normalization.records;

    const missingData =
        normalization.missingData;

    const averages =
        normalization.averages;


    const latestRecord =
        normalizedRecords[
            normalizedRecords.length - 1
        ];


    // --------------------------------------------------------
    // BUILD PROFILE
    // --------------------------------------------------------

    const mlProfile =
        buildProfile(profile);


    // --------------------------------------------------------
    // CALL PULSE AI SERVICE
    // --------------------------------------------------------

    console.log(
        `[ML Health] Starting analysis for user ${userId}`
    );

    console.log(
        `[ML Health] Records found: ${normalizedRecords.length}`
    );

    const pulseResponse =
        await analyzeWithPulseAI(
            mlProfile,
            normalizedRecords
        );


    // Support either:
    //
    // { data: {...} }
    //
    // or:
    //
    // {...}
    const mlResult =
        pulseResponse?.data ||
        pulseResponse;


    if (
        !mlResult ||
        typeof mlResult !== "object"
    ) {
        throw new Error(
            "Pulse AI returned an invalid response."
        );
    }


    // --------------------------------------------------------
    // EXTRACT RESULTS
    // --------------------------------------------------------

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


    // --------------------------------------------------------
    // SAVE ANALYSIS
    // --------------------------------------------------------

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
                "pulse-ai",
        });


    console.log(
        `[ML Health] Analysis completed successfully for user ${userId}`
    );


    return res.status(200).json({
        success: true,

        source:
            "pulse-ai",

        message:
            "ML health analysis completed and saved successfully.",

        data: {
            ...mlResult,

            latestHealthRecord:
                latestRecord,

            recordsAnalyzed:
                normalizedRecords.length,

            averagesUsed:
                averages,

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
    const errorData =
        error.response?.data ||
        error.message ||
        "Unknown error";

    console.error(
        "================================================"
    );

    console.error(
        "ML HEALTH ANALYSIS ERROR:"
    );

    console.error(
        errorData
    );

    console.error(
        "================================================"
    );

    return res.status(
        error.response?.status || 500
    ).json({
        success: false,

        message:
            "Unable to complete ML health analysis.",

        error:
            errorData,
    });
}


};

// ============================================================
// ML DASHBOARD
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

    const [
        latestAnalysis,
        latestHealthRecord,
    ] =
        await Promise.all([
            MLHealthAnalysis.findOne({
                user: userId,
            })
                .sort({
                    analyzedAt: -1,
                })
                .lean(),

            HealthRecord.findOne({
                userId: userId,
            })
                .sort({
                    date: -1,
                    syncedAt: -1,
                })
                .lean(),
        ]);


    return res.status(200).json({
        success: true,

        data: {
            analysis:
                latestAnalysis || null,

            latestHealthRecord:
                latestHealthRecord || null,

            hasHealthRecords:
                latestHealthRecord !== null,

            notifications:
                latestAnalysis
                    ?.missingData ||
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
        error:
            error.message,
    });
}


};

// ============================================================
// GET LATEST ML ANALYSIS
// ============================================================

exports.mlGetLatestAnalysis = async (
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

        data:
            analysis
                ? serializeAnalysis(
                    analysis
                )
                : null,
    });
} catch (error) {
    console.error(
        "ML LATEST ANALYSIS ERROR:",
        error
    );

    return res.status(500).json({
        success: false,
        message:
            "Unable to load latest ML analysis.",
        error:
            error.message,
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


    if (!userId) {
        return res.status(401).json({
            success: false,
            message:
                "User authentication required.",
        });
    }

    const days =
        Math.max(
            1,
            Math.min(
                Number(req.query.days) || 30,
                365
            )
        );

    const limit =
        Math.max(
            1,
            Math.min(
                Number(req.query.limit) || 100,
                365
            )
        );

    const startDate =
        new Date();

    startDate.setDate(
        startDate.getDate() - days
    );


    const history =
        await MLHealthAnalysis.find({
            user: userId,

            analyzedAt: {
                $gte: startDate,
            },
        })
            .sort({
                analyzedAt: -1,
            })
            .limit(limit)
            .lean();


    const formattedHistory =
        history.map(
            (item) =>
                serializeAnalysis(
                    item
                )
        );


    return res.status(200).json({
        success: true,

        data: {
            history:
                formattedHistory,

            count:
                formattedHistory.length,

            days,
        },
    });
} catch (error) {
    console.error(
        "ML HISTORY ERROR:",
        error
    );

    return res.status(500).json({
        success: false,
        message:
            "Unable to load ML history.",
        error:
            error.message,
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


    if (!userId) {
        return res.status(401).json({
            success: false,
            message:
                "User authentication required.",
        });
    }

    const analyses =
        await MLHealthAnalysis.find({
            user: userId,
        })
            .sort({
                analyzedAt: 1,
            })
            .limit(365)
            .lean();


    if (analyses.length < 2) {
        return res.status(200).json({
            success: true,

            data: {
                available: false,

                message:
                    "At least two ML analyses are required to calculate improvement.",
            },
        });
    }


    const first =
        analyses[0];

    const latest =
        analyses[
            analyses.length - 1
        ];


    return res.status(200).json({
        success: true,

        data: {
            available: true,

            firstAnalysis:
                serializeAnalysis(
                    first
                ),

            latestAnalysis:
                serializeAnalysis(
                    latest
                ),

            totalAnalyses:
                analyses.length,
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
            "Unable to calculate ML improvement.",
        error:
            error.message,
    });
}


};

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

// ============================================================
// CONFIGURATION
// ============================================================

const ML_API_URL =
process.env.ML_API_URL ||
"http://127.0.0.1:8000";

// ============================================================
// HELPERS
// ============================================================

function getUserId(req) {
return (
req.user?._id ||
req.user?.id ||
req.userId ||
null
);
}

function buildProfile(userProfile = {}, latestRecord = {}, averages = {}) {
    let sexVal = null;
    if (userProfile.sex === "Male") sexVal = 1;
    else if (userProfile.sex === "Female") sexVal = 0;

    let smokingVal = 0;
    if (userProfile.smokingStatus === "Yes" || userProfile.smokingStatus === "Occasionally") smokingVal = 1;

    let alcoholVal = 0;
    if (userProfile.alcoholConsumption === "Yes" || userProfile.alcoholConsumption === "Occasionally") alcoholVal = 1;

    let heightCm = userProfile.height ?? null;
    let weightKg = userProfile.weight ?? null;
    let bmi = userProfile.bmi ?? null;

    // Appropriate Method: Calculate BMI if missing but height & weight exist
    if (bmi === null && heightCm != null && weightKg != null && heightCm > 0) {
        const heightM = heightCm / 100;
        bmi = Number((weightKg / (heightM * heightM)).toFixed(2));
    }

    // Appropriate Method: Fallback to user's historical averages for missing daily metrics
    let activityMinutes = null;
    if (latestRecord && latestRecord.activeZoneMinutes != null) {
        activityMinutes = latestRecord.activeZoneMinutes;
    } else if (latestRecord && latestRecord.activeHours != null) {
        activityMinutes = latestRecord.activeHours * 60;
    } else if (averages && averages.activeZoneMinutes != null) {
        activityMinutes = averages.activeZoneMinutes;
    } else if (averages && averages.activeHours != null) {
        activityMinutes = averages.activeHours * 60;
    }

    let heartRate = (latestRecord && latestRecord.heartRate) ?? (averages && averages.heartRate) ?? null;
    let sleepHours = (latestRecord && latestRecord.sleepHours) ?? (averages && averages.sleepHours) ?? userProfile.sleepTargetHours ?? null;

    return {
        age: userProfile.age ?? null,
        sex: sexVal,
        height_cm: heightCm,
        weight_kg: weightKg,
        bmi: bmi,
        waist_cm: userProfile.waistCircumference ?? null,

        heart_rate: heartRate,
        activity_minutes: activityMinutes,
        sleep_hours: sleepHours,

        smoking: smokingVal,
        alcohol: alcoholVal,
    };
}

function serializeAnalysis(analysis) {
if (!analysis) {
return null;
}


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
// GET LATEST HEALTH RECORDS
// ============================================================

async function getLatestHealthRecords(
userId,
limit = 30
) {
const records =
await HealthRecord.find({
userId: userId,
})
.sort({
date: -1,
syncedAt: -1,
createdAt: -1,
})
.limit(limit)
.lean();


return records || [];


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


    const records =
        await getLatestHealthRecords(
            userId,
            30
        );


    return res.status(200).json({
        success: true,

        message:
            records.length
                ? "Latest health records retrieved successfully."
                : "No health records available.",

        data: {
            latestRecord:
                records.length
                    ? records[0]
                    : null,

            records,

            count:
                records.length,
        },
    });

} catch (error) {
    console.error(
        "LATEST HEALTH RECORD ERROR:",
        error
    );

    return res.status(500).json({
        success: false,

        message:
            "Unable to retrieve health records.",

        error:
            error.message,
    });
}


};

// ============================================================
// ANALYZE HEALTH
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


    // ====================================================
    // ALWAYS GET THE LATEST HEALTH RECORDS FROM DATABASE
    // ====================================================

    let healthRecords =
        await getLatestHealthRecords(
            userId,
            30
        );


    if (!healthRecords.length) {
        return res.status(400).json({
            success: false,

            message:
                "No health records available for Wellness analysis. Please sync health data first.",
        });
    }


    // ====================================================
    // DATABASE RETURNS NEWEST FIRST
    // ML SHOULD RECEIVE OLDEST -> NEWEST
    // ====================================================

    healthRecords =
        [...healthRecords].reverse();


    // ====================================================
    // NORMALIZE HEALTH DATA
    //
    // Missing fields are filled using available averages
    // from the user's health records.
    // ====================================================

    const normalization =
        normalizeHealthRecords(
            healthRecords
        );


    const normalizedRecords =
        normalization.records ||
        [];


    const missingData =
        normalization.missingData ||
        [];


    const averages =
        normalization.averages ||
        {};


    if (!normalizedRecords.length) {
        return res.status(400).json({
            success: false,

            message:
                "Health records could not be prepared for Wellness analysis.",
        });
    }


    // ====================================================
    // LATEST RECORD
    // ====================================================

    const latestRecord =
        normalizedRecords[
            normalizedRecords.length - 1
        ];


    // ====================================================
    // BUILD ML PROFILE
    // ====================================================

    const mlProfile =
        buildProfile(profile, latestRecord, averages);


    // ====================================================
    // CALL PYTHON ML SERVICE
    // ====================================================

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
        mlResponse.data ||
        {};


    // ====================================================
    // EXTRACT RESULTS
    // ====================================================

    const scores =
        mlResult.scores ||
        {};

    const dimensions =
        extractLatestDimensions(
            mlResult
        ) ||
        {};

    const forecast =
        mlResult.forecast ||
        {};

    const dataQuality =
        mlResult.dataQuality ||
        mlResult.wellness
            ?.dataQuality ||
        {};


    // ====================================================
    // SAVE AS A NEW ML ANALYSIS
    //
    // Since /latest sorts by analyzedAt descending,
    // this newly created analysis automatically becomes
    // the latest analysis.
    // ====================================================

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


    console.log(
        `[ML Health] Analysis completed for user ${userId}`
    );

    console.log(
        `[ML Health] Latest record date: ${latestRecord.date}`
    );

    console.log(
        `[ML Health] Records analyzed: ${normalizedRecords.length}`
    );


    return res.status(200).json({
        success: true,

        source:
            "pulse-ai",

        message:
            "Wellness analysis completed and saved successfully.",

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
        "ML HEALTH ANALYSIS ERROR:",
        errorData
    );

    return res.status(500).json({
        success: false,

        message:
            "Unable to complete Wellness analysis.",

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
                latestAnalysis ||
                null,

            latestHealthRecord:
                latestHealthRecord ||
                null,

            hasHealthRecords:
                latestHealthRecord !==
                null,

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
            "Unable to load Wellness dashboard.",
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


    const limit =
        Math.min(
            Number(req.query.limit) || 100,
            365
        );


    const history =
        await MLHealthAnalysis.find({
            user: userId,
        })
            .sort({
                analyzedAt: -1,
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

                sourceRecordDate:
                    item.sourceRecordDate,

                recordsAnalyzed:
                    item.recordsAnalyzed,

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
            "Unable to load Wellness health history.",
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
            .lean();


    if (!analyses.length) {
        return res.status(200).json({
            success: true,

            data: {
                totalAnalyses: 0,

                summary:
                    null,

                history:
                    [],
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
        const latestNumber =
            Number(latestValue);

        const firstNumber =
            Number(firstValue);

        if (
            !Number.isFinite(
                latestNumber
            ) ||
            !Number.isFinite(
                firstNumber
            )
        ) {
            return null;
        }

        return Number(
            (
                latestNumber -
                firstNumber
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

                sourceRecordDate:
                    item.sourceRecordDate,

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

        message:
            analysis
                ? "Latest ML analysis retrieved successfully."
                : "No ML analysis available yet.",

        data:
            analysis ||
            null,
    });

} catch (error) {
    console.error(
        "LATEST ML ANALYSIS ERROR:",
        error
    );

    return res.status(500).json({
        success: false,

        message:
            "Unable to load latest analysis.",
    });
}


};

// ============================================================
// GET WELLNESS SUMMARIES (1D, 7D, 30D)
// ============================================================
exports.getWellnessSummaries = async (req, res) => {
    try {
        const userId = getUserId(req);
        if (!userId) {
            return res.status(401).json({ success: false, message: "User authentication required." });
        }

        const UserProfile = require("../models/UserProfile");
        const userProfile = await UserProfile.findOne({ userId }) || {};

        let healthRecords = await getLatestHealthRecords(userId, 30);
        if (!healthRecords.length) {
            return res.status(400).json({ success: false, message: "No health records available." });
        }

        // Reverse to Oldest -> Newest
        healthRecords = [...healthRecords].reverse();

        async function getScore(sliceLength) {
            const recordsSlice = healthRecords.slice(-sliceLength);
            if (!recordsSlice.length) return null;
            
            const normalization = normalizeHealthRecords(recordsSlice);
            const normalizedRecords = normalization.records || [];
            const averages = normalization.averages || {};
            const latestRecord = normalizedRecords[normalizedRecords.length - 1];
            
            const mlProfile = buildProfile(userProfile, latestRecord, averages);
            
            const response = await axios.post(`${ML_API_URL}/api/v1/analyze`, {
                profile: mlProfile,
                health_records: normalizedRecords,
            }, { timeout: 30000 });
            
            const healthScore = response.data?.data?.scores?.health || response.data?.scores?.health || 0;
            return Math.round(healthScore * 100);
        }

        const [score1d, score7d, score30d] = await Promise.all([
            getScore(1),
            getScore(7),
            getScore(30)
        ]);

        let trendInsight = "Not enough data to determine a trend.";
        if (score7d !== null && score30d !== null) {
            if (score7d < score30d - 2) {
                trendInsight = "Your recent 7-day wellness trend is dropping compared to your monthly average. If you follow this trend, it could negatively impact your long-term health. Consider resting or checking your stress levels.";
            } else if (score7d > score30d + 2) {
                trendInsight = "Great job! Your 7-day wellness trend is improving compared to your monthly average. Keep following this routine for better health outcomes.";
            } else {
                trendInsight = "Your wellness trend is stable and consistent with your monthly average. Keep it up!";
            }
        }

        return res.status(200).json({
            success: true,
            message: "Wellness summaries calculated successfully",
            data: {
                latestScore: score1d,
                weeklyScore: score7d,
                monthlyScore: score30d,
                trendInsight: trendInsight
            }
        });
    } catch (error) {
        console.error("WELLNESS SUMMARIES ERROR:", error.message || error);
        return res.status(500).json({ success: false, message: "Unable to calculate wellness summaries." });
    }
};

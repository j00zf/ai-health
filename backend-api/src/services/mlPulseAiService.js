const axios = require("axios");


// ============================================================
// CONFIGURATION
// ============================================================

const PULSE_AI_URL =
    process.env.PULSE_AI_URL ||
    "http://127.0.0.1:8000/api/v1/analyze";

const PULSE_AI_TIMEOUT =
    Number(
        process.env.PULSE_AI_TIMEOUT || 30000
    );


// ============================================================
// VALIDATION
// ============================================================

function validateProfile(profile) {

    if (!profile || typeof profile !== "object") {

        throw new Error(
            "ML profile is required"
        );
    }

    return true;
}


function validateHealthRecords(
    healthRecords
) {

    if (
        healthRecords !== undefined &&
        !Array.isArray(healthRecords)
    ) {

        throw new Error(
            "ML health_records must be an array"
        );
    }

    return true;
}


// ============================================================
// PROFILE NORMALIZATION
// ============================================================

function parseBooleanToInt(val) {
    if (val === null || val === undefined) return null;
    if (typeof val === 'number') return val;
    if (typeof val === 'boolean') return val ? 1 : 0;
    const lower = String(val).toLowerCase().trim();
    if (['no', 'false', '0', 'none', 'never'].includes(lower)) return 0;
    if (['yes', 'true', '1', 'often', 'sometimes'].includes(lower)) return 1;
    const parsed = parseInt(val, 10);
    return isNaN(parsed) ? 0 : parsed;
}

function normalizeProfile(profile) {

    return {

        age:
            profile.age ?? null,

        sex:
            profile.sex ?? null,

        height_cm:
            profile.height_cm ?? null,

        weight_kg:
            profile.weight_kg ?? null,

        bmi:
            profile.bmi ?? null,

        waist_cm:
            profile.waist_cm ?? null,

        heart_rate:
            profile.heart_rate ?? null,

        activity_minutes:
            profile.activity_minutes ?? null,

        sleep_hours:
            profile.sleep_hours ?? null,

        smoking:
            parseBooleanToInt(profile.smoking),

        alcohol:
            parseBooleanToInt(profile.alcohol),
    };
}


// ============================================================
// HEALTH RECORD NORMALIZATION
// ============================================================

function normalizeHealthRecord(
    record
) {

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

        sleepHours:
            record.sleepHours ?? null,

        weight:
            record.weight ?? null,

        bmi:
            record.bmi ?? null,

        bloodOxygen:
            record.bloodOxygen ?? null,

        calories:
            record.calories ?? null,

        distanceWalked:
            record.distanceWalked ?? null,
            
        bodyTemperature:
            record.bodyTemperature ?? null,
            
        floors:
            record.floors ?? null,
    };
}


// ============================================================
// BUILD ML PAYLOAD
// ============================================================

function buildMlPayload(
    profile,
    healthRecords
) {

    return {

        profile:
            normalizeProfile(
                profile
            ),

        health_records:
            healthRecords.map(
                normalizeHealthRecord
            ),
    };
}


// ============================================================
// CALL PYTHON PULSE AI
// ============================================================

async function analyzeWithPulseAI(
    profile,
    healthRecords = []
) {

    validateProfile(
        profile
    );

    validateHealthRecords(
        healthRecords
    );


    const payload =
        buildMlPayload(
            profile,
            healthRecords || []
        );


    try {

        const response =
            await axios.post(

                PULSE_AI_URL,

                payload,

                {
                    timeout:
                        PULSE_AI_TIMEOUT,

                    headers: {

                        "Content-Type":
                            "application/json",

                        Accept:
                            "application/json",
                    },
                }
            );


        return response.data;

    } catch (error) {

        console.error(
            "================================================"
        );

        console.error(
            "PULSE AI SERVICE ERROR"
        );

        console.error(
            "================================================"
        );


        if (error.response) {

            console.error(
                "Status:",
                error.response.status
            );

            console.error(
                "Response:",
                error.response.data
            );

        } else {

            console.error(
                "Message:",
                error.message
            );
        }


        throw error;
    }
}


// ============================================================
// HEALTH CHECK
// ============================================================

async function checkPulseAiHealth() {

    const healthUrl =
        process.env.PULSE_AI_HEALTH_URL ||
        "http://127.0.0.1:8000/health";


    try {

        const response =
            await axios.get(

                healthUrl,

                {
                    timeout: 5000,
                }
            );


        return {

            available:
                true,

            status:
                response.status,

            data:
                response.data,
        };

    } catch (error) {

        return {

            available:
                false,

            status:
                null,

            data:
                null,

            error:
                error.message,
        };
    }
}


// ============================================================
// EXPORT
// ============================================================

module.exports = {

    analyzeWithPulseAI,

    checkPulseAiHealth,

    normalizeProfile,

    normalizeHealthRecord,

    buildMlPayload,
};
const axios = require("axios");

// ============================================================
// PULSE AI CONFIGURATION
// ============================================================

const PULSE_AI_URL =
    process.env.PULSE_AI_URL ||
    "http://127.0.0.1:8000/api/v1/analyze";


// ============================================================
// AXIOS CLIENT
// ============================================================

const pulseAiClient = axios.create({
    timeout: 120000,
    headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
    },
});


// ============================================================
// DEFAULT VALUES
//
// These values are only used when a field is unavailable.
// The ML controller can still provide record-based averages
// before calling this service.
// ============================================================

const DEFAULTS = {
    age: 30,
    sex: 0,
    height_cm: 170,
    weight_kg: 70,
    bmi: 24,
    waist_cm: 85,
    heart_rate: 75,
    activity_minutes: 30,
    sleep_hours: 7,
    smoking: 0,
    alcohol: 0,

    steps: 5000,
    activeHours: 8,
    activeZoneMinutes: 30,
    heartRate: 75,
    restingHeartRate: 65,
    sleep: 7,
    weight: 70,
    oxygenSaturation: 98,
    calories: 2000,
    distance: 4,
};


// ============================================================
// NUMBER HELPER
// ============================================================

function toNumber(value) {
    if (
        value === null ||
        value === undefined ||
        value === ""
    ) {
        return null;
    }

    const number = Number(value);

    return Number.isFinite(number)
        ? number
        : null;
}


// ============================================================
// NUMBER WITH FALLBACK
// ============================================================

function numberOrDefault(
    value,
    fallback
) {
    const number = toNumber(value);

    if (number === null) {
        return fallback;
    }

    return number;
}


// ============================================================
// CLAMP VALUE
// ============================================================

function clamp(
    value,
    minimum,
    maximum,
    fallback = null
) {
    let number = toNumber(value);

    if (number === null) {
        number = fallback;
    }

    if (number === null) {
        return null;
    }

    return Math.min(
        Math.max(number, minimum),
        maximum
    );
}


// ============================================================
// SAFE BINARY CONVERSION
//
// 0 = female / false / no
// 1 = male / true / yes
// ============================================================

function toBinary(
    value,
    fallback = 0
) {
    if (
        value === null ||
        value === undefined ||
        value === ""
    ) {
        return fallback;
    }

    if (
        value === true ||
        value === 1 ||
        value === "1"
    ) {
        return 1;
    }

    const normalized =
        String(value)
            .trim()
            .toLowerCase();

    if (
        normalized === "male" ||
        normalized === "m" ||
        normalized === "true" ||
        normalized === "yes" ||
        normalized === "y"
    ) {
        return 1;
    }

    if (
        normalized === "female" ||
        normalized === "f" ||
        normalized === "false" ||
        normalized === "no" ||
        normalized === "n"
    ) {
        return 0;
    }

    return fallback;
}


// ============================================================
// DATE NORMALIZATION
//
// FastAPI requires a non-empty string.
// ============================================================

function normalizeDate(value) {
    if (
        value === null ||
        value === undefined ||
        value === ""
    ) {
        return new Date()
            .toISOString()
            .split("T")[0];
    }

    if (value instanceof Date) {
        if (
            !Number.isNaN(
                value.getTime()
            )
        ) {
            return value
                .toISOString()
                .split("T")[0];
        }
    }

    if (typeof value === "string") {
        const trimmed = value.trim();

        if (trimmed) {
            const parsed =
                new Date(trimmed);

            if (
                !Number.isNaN(
                    parsed.getTime()
                )
            ) {
                return parsed
                    .toISOString()
                    .split("T")[0];
            }

            // Return string if already a date-like
            // value accepted by FastAPI.
            return trimmed;
        }
    }

    const parsedDate =
        new Date(value);

    if (
        !Number.isNaN(
            parsedDate.getTime()
        )
    ) {
        return parsedDate
            .toISOString()
            .split("T")[0];
    }

    return new Date()
        .toISOString()
        .split("T")[0];
}


// ============================================================
// GET FIRST AVAILABLE VALUE
// ============================================================

function firstAvailable(...values) {
    for (const value of values) {
        if (
            value !== null &&
            value !== undefined &&
            value !== ""
        ) {
            return value;
        }
    }

    return null;
}


// ============================================================
// PROFILE NORMALIZATION
//
// Converts Node/database profile fields into the exact
// structure expected by the Pulse AI API.
// ============================================================

function normalizeProfile(profile = {}) {
    return {
        age:
            clamp(
                firstAvailable(
                    profile.age,
                    profile.age_years
                ),
                1,
                120,
                DEFAULTS.age
            ),

        sex:
            toBinary(
                firstAvailable(
                    profile.sex,
                    profile.gender
                ),
                DEFAULTS.sex
            ),

        height_cm:
            clamp(
                firstAvailable(
                    profile.height_cm,
                    profile.height
                ),
                50,
                250,
                DEFAULTS.height_cm
            ),

        weight_kg:
            clamp(
                firstAvailable(
                    profile.weight_kg,
                    profile.weight
                ),
                10,
                300,
                DEFAULTS.weight_kg
            ),

        bmi:
            clamp(
                profile.bmi,
                5,
                100,
                DEFAULTS.bmi
            ),

        waist_cm:
            clamp(
                firstAvailable(
                    profile.waist_cm,
                    profile.waist
                ),
                20,
                250,
                DEFAULTS.waist_cm
            ),

        heart_rate:
            clamp(
                firstAvailable(
                    profile.heart_rate,
                    profile.heartRate
                ),
                20,
                250,
                DEFAULTS.heart_rate
            ),

        activity_minutes:
            clamp(
                firstAvailable(
                    profile.activity_minutes,
                    profile.activityMinutes
                ),
                0,
                2000,
                DEFAULTS.activity_minutes
            ),

        sleep_hours:
            clamp(
                firstAvailable(
                    profile.sleep_hours,
                    profile.sleepHours
                ),
                0,
                24,
                DEFAULTS.sleep_hours
            ),

        smoking:
            toBinary(
                firstAvailable(
                    profile.smoking,
                    profile.smoke
                ),
                DEFAULTS.smoking
            ),

        alcohol:
            toBinary(
                profile.alcohol,
                DEFAULTS.alcohol
            ),
    };
}


// ============================================================
// HEALTH RECORD NORMALIZATION
//
// Database schema aliases are converted to the exact ML API
// field names.
// ============================================================

function normalizeHealthRecord(record = {}) {
    return {
        date:
            normalizeDate(
                firstAvailable(
                    record.date,
                    record.recordedAt,
                    record.createdAt,
                    record.syncedAt
                )
            ),

        steps:
            clamp(
                record.steps,
                0,
                200000,
                DEFAULTS.steps
            ),

        activeHours:
            clamp(
                firstAvailable(
                    record.activeHours,
                    record.activityHours
                ),
                0,
                24,
                DEFAULTS.activeHours
            ),

        activeZoneMinutes:
            clamp(
                firstAvailable(
                    record.activeZoneMinutes,
                    record.activeMinutes
                ),
                0,
                1440,
                DEFAULTS.activeZoneMinutes
            ),

        heartRate:
            clamp(
                firstAvailable(
                    record.heartRate,
                    record.averageHeartRate
                ),
                20,
                250,
                DEFAULTS.heartRate
            ),

        restingHeartRate:
            clamp(
                record.restingHeartRate,
                20,
                200,
                DEFAULTS.restingHeartRate
            ),

        sleep:
            clamp(
                firstAvailable(
                    record.sleep,
                    record.sleepHours
                ),
                0,
                24,
                DEFAULTS.sleep
            ),

        weight:
            clamp(
                record.weight,
                10,
                300,
                DEFAULTS.weight
            ),

        bmi:
            clamp(
                record.bmi,
                5,
                100,
                DEFAULTS.bmi
            ),

        oxygenSaturation:
            clamp(
                firstAvailable(
                    record.oxygenSaturation,
                    record.bloodOxygen
                ),
                50,
                100,
                DEFAULTS.oxygenSaturation
            ),

        calories:
            clamp(
                firstAvailable(
                    record.calories,
                    record.caloriesBurned
                ),
                0,
                20000,
                DEFAULTS.calories
            ),

        distance:
            clamp(
                firstAvailable(
                    record.distance,
                    record.distanceWalked
                ),
                0,
                1000,
                DEFAULTS.distance
            ),
    };
}


// ============================================================
// ANALYZE WITH PULSE AI
// ============================================================

async function analyzeWithPulseAI(
    profile = {},
    healthRecords = []
) {
    try {
        // ----------------------------------------------------
        // NORMALIZE PROFILE
        // ----------------------------------------------------

        const normalizedProfile =
            normalizeProfile(profile);


        // ----------------------------------------------------
        // NORMALIZE HEALTH RECORDS
        // ----------------------------------------------------

        let normalizedRecords = [];

        if (Array.isArray(healthRecords)) {
            normalizedRecords =
                healthRecords.map(
                    (record) =>
                        normalizeHealthRecord(
                            record || {}
                        )
                );
        }


        // ----------------------------------------------------
        // ENSURE AT LEAST ONE RECORD EXISTS
        // ----------------------------------------------------

        if (normalizedRecords.length === 0) {
            normalizedRecords.push(
                normalizeHealthRecord({})
            );
        }


        // ----------------------------------------------------
        // BUILD EXACT FASTAPI PAYLOAD
        // ----------------------------------------------------

        const payload = {
            profile:
                normalizedProfile,

            health_records:
                normalizedRecords,
        };


        // ----------------------------------------------------
        // DEBUG LOGGING
        // ----------------------------------------------------

        console.log(
            "\n========================================"
        );

        console.log(
            "[Pulse AI] Starting ML analysis"
        );

        console.log(
            "[Pulse AI] Request URL:",
            PULSE_AI_URL
        );

        console.log(
            "[Pulse AI] Health records:",
            normalizedRecords.length
        );

        console.log(
            "[Pulse AI] Profile:"
        );

        console.dir(
            normalizedProfile,
            {
                depth: null,
            }
        );

        console.log(
            "[Pulse AI] Latest record:"
        );

        console.dir(
            normalizedRecords[
                normalizedRecords.length - 1
            ],
            {
                depth: null,
            }
        );

        console.log(
            "[Pulse AI] Full payload:"
        );

        console.dir(
            payload,
            {
                depth: null,
            }
        );

        console.log(
            "========================================\n"
        );


        // ----------------------------------------------------
        // CALL FASTAPI
        // ----------------------------------------------------

        const response =
            await pulseAiClient.post(
                PULSE_AI_URL,
                payload
            );


        console.log(
            "[Pulse AI] Analysis successful."
        );


        if (!response.data) {
            throw new Error(
                "Pulse AI returned an empty response."
            );
        }


        return response.data;
    } catch (error) {
        console.error(
            "\n========================================"
        );

        console.error(
            "[Pulse AI] SERVICE ERROR"
        );

        if (error.response) {
            console.error(
                "[Pulse AI] HTTP Status:",
                error.response.status
            );

            console.error(
                "[Pulse AI] Response data:"
            );

            console.dir(
                error.response.data,
                {
                    depth: null,
                }
            );

            console.error(
                "[Pulse AI] Request URL:",
                PULSE_AI_URL
            );
        } else if (error.request) {
            console.error(
                "[Pulse AI] No response received."
            );

            console.error(
                "[Pulse AI] Request URL:",
                PULSE_AI_URL
            );

            console.error(
                "[Pulse AI] Possible causes:"
            );

            console.error(
                "- Pulse AI service is not running"
            );

            console.error(
                "- Incorrect PULSE_AI_URL"
            );

            console.error(
                "- Network/firewall connection issue"
            );

            console.error(
                "- Request timed out"
            );
        } else {
            console.error(
                "[Pulse AI] Error:",
                error.message
            );
        }

        console.error(
            "========================================\n"
        );

        throw error;
    }
}


// ============================================================
// MODULE EXPORTS
// ============================================================

module.exports = {
    analyzeWithPulseAI,
    normalizeProfile,
    normalizeHealthRecord,
};
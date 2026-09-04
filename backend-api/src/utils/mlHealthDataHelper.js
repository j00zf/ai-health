const NUMERIC_FIELDS = [
    "steps",
    "activeHours",
    "activeZoneMinutes",
    "heartRate",
    "restingHeartRate",
    "sleepHours",
    "weight",
    "bmi",
    "bloodOxygen",
    "calories",
    "distanceWalked",
    "bodyTemperature",
    "floors"
];

// Fields where a value of 0 is biologically impossible/invalid
const NON_ZERO_FIELDS = [
    "heartRate",
    "restingHeartRate",
    "weight",
    "bmi",
    "bloodOxygen",
    "bodyTemperature"
];

function isValidNumber(value, field) {
    if (value === null || value === undefined || value === "" || Number.isNaN(Number(value))) {
        return false;
    }
    const num = Number(value);
    
    // Treat 0 as invalid for fields like heartRate, weight, etc.
    if (num === 0 && NON_ZERO_FIELDS.includes(field)) {
        return false;
    }
    return true;
}

function calculateStats(records, field) {
    const values = records
        .map((record) => record[field])
        .filter((val) => isValidNumber(val, field))
        .map(Number);

    if (!values.length) {
        return { mean: null, stdDev: null };
    }

    const total = values.reduce((sum, value) => sum + value, 0);
    const mean = total / values.length;

    // Calculate Standard Deviation
    const variance = values.reduce((sum, value) => sum + Math.pow(value - mean, 2), 0) / values.length;
    const stdDev = Math.sqrt(variance);

    return { 
        mean: Number(mean.toFixed(2)), 
        stdDev: Number(stdDev.toFixed(2)) 
    };
}

function normalizeHealthRecords(records = []) {
    const missingData = [];
    const stats = {};
    const averages = {};

    for (const field of NUMERIC_FIELDS) {
        const fieldStats = calculateStats(records, field);
        stats[field] = fieldStats;
        averages[field] = fieldStats.mean; // Keep averages object for backward compatibility
    }

    const normalizedRecords = records.map((record, recordIndex) => {
        const normalized = { ...record };

        for (const field of NUMERIC_FIELDS) {
            let val = normalized[field];
            let isMissingOrAnomaly = !isValidNumber(val, field);
            
            const fieldStats = stats[field];
            
            // Anomaly detection using Standard Deviation (e.g., > 3 std devs from mean)
            if (!isMissingOrAnomaly && fieldStats.stdDev !== null && fieldStats.stdDev > 0) {
                const num = Number(val);
                if (Math.abs(num - fieldStats.mean) > 3 * fieldStats.stdDev) {
                    isMissingOrAnomaly = true;
                }
            }

            if (isMissingOrAnomaly) {
                const averageValue = fieldStats.mean;

                if (averageValue !== null) {
                    normalized[field] = averageValue;

                    missingData.push({
                        recordIndex,
                        field,
                        message: `${field} was missing, 0, or anomalous. The mean value was used for imputation.`,
                        fallbackValue: averageValue,
                    });
                } else {
                     // If no historical mean is available, ensure we pass null so ML backend's SimpleImputer handles it
                     normalized[field] = null;
                }
            } else {
                normalized[field] = Number(normalized[field]);
            }
        }

        return normalized;
    });

    return {
        records: normalizedRecords,
        missingData,
        averages,
        stats
    };
}

function extractLatestDimensions(mlData = {}) {
    const windows =
        mlData?.wellness?.windows || {};

    const latestWindow =
        windows["7d"] || {};

    return (
        latestWindow.dimensions ||
        mlData?.currentDimensions ||
        {}
    );
}

module.exports = {
    NUMERIC_FIELDS,
    normalizeHealthRecords,
    extractLatestDimensions,
};
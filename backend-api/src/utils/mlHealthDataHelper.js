const NUMERIC_FIELDS = [
    "steps",
    "activeHours",
    "activeZoneMinutes",
    "heartRate",
    "restingHeartRate",
    "sleep",
    "weight",
    "bmi",
    "oxygenSaturation",
    "calories",
    "distance",
];

function isValidNumber(value) {
    return (
        value !== null &&
        value !== undefined &&
        value !== "" &&
        !Number.isNaN(Number(value))
    );
}

function calculateAverage(records, field) {
    const values = records
        .map((record) => record[field])
        .filter(isValidNumber)
        .map(Number);

    if (!values.length) {
        return null;
    }

    const total = values.reduce(
        (sum, value) => sum + value,
        0
    );

    return Number(
        (total / values.length).toFixed(2)
    );
}

function normalizeHealthRecords(records = []) {
    const missingData = [];

    const averages = {};

    for (const field of NUMERIC_FIELDS) {
        averages[field] = calculateAverage(
            records,
            field
        );
    }

    const normalizedRecords = records.map(
        (record, recordIndex) => {
            const normalized = {
                ...record,
            };

            for (const field of NUMERIC_FIELDS) {
                if (!isValidNumber(normalized[field])) {
                    const averageValue =
                        averages[field];

                    if (averageValue !== null) {
                        normalized[field] =
                            averageValue;

                        missingData.push({
                            recordIndex,
                            field,
                            message:
                                `${field} was missing and the average available value was used.`,
                            fallbackValue:
                                averageValue,
                        });
                    }
                } else {
                    normalized[field] =
                        Number(normalized[field]);
                }
            }

            return normalized;
        }
    );

    return {
        records: normalizedRecords,
        missingData,
        averages,
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
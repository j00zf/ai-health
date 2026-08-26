from typing import Any, Dict, List, Optional

import statistics


# ============================================================
# CONFIGURATION
# ============================================================

MIN_DATA_POINTS = 3


MAX_ADJUSTMENT = 15.0


# ============================================================
# SAFE NUMBER
# ============================================================

def safe_float(
    value: Any
) -> Optional[float]:

    try:

        if value is None:
            return None

        return float(value)

    except (
        TypeError,
        ValueError
    ):

        return None


# ============================================================
# CLEAN VALUES
# ============================================================

def clean_values(
    values: List[Any]
) -> List[float]:

    cleaned = []

    for value in values:

        number = safe_float(
            value
        )

        if number is not None:

            cleaned.append(
                number
            )

    return cleaned


# ============================================================
# TREND
# ============================================================

def calculate_trend(
    values: List[Any]
) -> str:

    values = clean_values(
        values
    )


    if len(values) < 2:

        return "insufficient_data"


    first = values[0]

    last = values[-1]


    if first == 0:

        return "stable"


    change = (
        (last - first)
        /
        abs(first)
    ) * 100


    if change >= 5:

        return "increasing"


    if change <= -5:

        return "decreasing"


    return "stable"


# ============================================================
# CHANGE %
# ============================================================

def calculate_change(
    values: List[Any]
) -> Optional[float]:

    values = clean_values(
        values
    )


    if len(values) < 2:

        return None


    first = values[0]

    last = values[-1]


    if first == 0:

        return None


    return round(
        (
            (last - first)
            /
            abs(first)
        )
        * 100,
        2
    )


# ============================================================
# AVERAGE
# ============================================================

def average(
    values: List[Any]
) -> Optional[float]:

    values = clean_values(
        values
    )


    if not values:

        return None


    return round(
        statistics.mean(
            values
        ),
        2
    )


# ============================================================
# WELLNESS ENGINE
# ============================================================

def analyze_wellness(
    records: List[Dict[str, Any]],
    baseline_score: float,
) -> Dict[str, Any]:

    # --------------------------------------------------------
    # No data
    # --------------------------------------------------------

    if not records:

        return {

            "personalWellnessScore":
                round(
                    baseline_score,
                    2
                ),

            "baselineScore":
                round(
                    baseline_score,
                    2
                ),

            "adjustment":
                0.0,

            "status":
                "insufficient_data",

            "dataPoints":
                0,

            "trends":
                {},

            "changes":
                {},

            "averages":
                {},

            "signals":
                [],

            "recommendations":
                [],
        }


    # ========================================================
    # Extract data
    # ========================================================

    activity = [

        record.get(
            "activity_minutes"
        )

        for record in records
    ]


    steps = [

        record.get(
            "steps"
        )

        for record in records
    ]


    sleep = [

        record.get(
            "sleep_hours"
        )

        for record in records
    ]


    heart_rate = [

        record.get(
            "heart_rate"
        )

        for record in records
    ]


    resting_hr = [

        record.get(
            "resting_heart_rate"
        )

        for record in records
    ]


    weight = [

        record.get(
            "weight_kg"
        )

        for record in records
    ]


    bmi = [

        record.get(
            "bmi"
        )

        for record in records
    ]


    spo2 = [

        record.get(
            "spo2"
        )

        for record in records
    ]


    calories = [

        record.get(
            "calories"
        )

        for record in records
    ]


    # ========================================================
    # Trends
    # ========================================================

    trends = {

        "activity":
            calculate_trend(
                activity
            ),

        "steps":
            calculate_trend(
                steps
            ),

        "sleep":
            calculate_trend(
                sleep
            ),

        "heartRate":
            calculate_trend(
                heart_rate
            ),

        "restingHeartRate":
            calculate_trend(
                resting_hr
            ),

        "weight":
            calculate_trend(
                weight
            ),

        "bmi":
            calculate_trend(
                bmi
            ),

        "spo2":
            calculate_trend(
                spo2
            ),

        "calories":
            calculate_trend(
                calories
            ),
    }


    # ========================================================
    # Changes
    # ========================================================

    changes = {

        "activity":
            calculate_change(
                activity
            ),

        "steps":
            calculate_change(
                steps
            ),

        "sleep":
            calculate_change(
                sleep
            ),

        "heartRate":
            calculate_change(
                heart_rate
            ),

        "restingHeartRate":
            calculate_change(
                resting_hr
            ),

        "weight":
            calculate_change(
                weight
            ),

        "bmi":
            calculate_change(
                bmi
            ),

        "spo2":
            calculate_change(
                spo2
            ),

        "calories":
            calculate_change(
                calories
            ),
    }


    # ========================================================
    # Averages
    # ========================================================

    averages = {

        "activityMinutes":
            average(
                activity
            ),

        "steps":
            average(
                steps
            ),

        "sleepHours":
            average(
                sleep
            ),

        "heartRate":
            average(
                heart_rate
            ),

        "restingHeartRate":
            average(
                resting_hr
            ),

        "weightKg":
            average(
                weight
            ),

        "bmi":
            average(
                bmi
            ),

        "spo2":
            average(
                spo2
            ),

        "calories":
            average(
                calories
            ),
    }


    # ========================================================
    # Adjustment
    # ========================================================

    adjustment = 0.0


    signals = []


    recommendations = []


    # ========================================================
    # ACTIVITY
    # ========================================================

    activity_change = (
        changes["activity"]
    )


    if activity_change is not None:

        if activity_change >= 10:

            adjustment += 3

            signals.append(
                "activity_improving"
            )


        elif activity_change <= -10:

            adjustment -= 3

            signals.append(
                "activity_declining"
            )

            recommendations.append(
                "Gradually increase daily "
                "physical activity and maintain "
                "consistency."
            )


    # ========================================================
    # STEPS
    # ========================================================

    steps_change = (
        changes["steps"]
    )


    if steps_change is not None:

        if steps_change >= 10:

            adjustment += 2

            signals.append(
                "step_count_improving"
            )


        elif steps_change <= -15:

            adjustment -= 2

            signals.append(
                "step_count_declining"
            )


    # ========================================================
    # SLEEP
    # ========================================================

    sleep_change = (
        changes["sleep"]
    )


    if sleep_change is not None:

        if sleep_change >= 5:

            adjustment += 3

            signals.append(
                "sleep_improving"
            )


        elif sleep_change <= -10:

            adjustment -= 4

            signals.append(
                "sleep_declining"
            )

            recommendations.append(
                "Focus on maintaining a consistent "
                "sleep schedule and adequate sleep."
            )


    # ========================================================
    # RESTING HEART RATE
    # ========================================================

    resting_change = (
        changes["restingHeartRate"]
    )


    if resting_change is not None:

        if resting_change <= -5:

            adjustment += 2

            signals.append(
                "resting_heart_rate_improving"
            )


        elif resting_change >= 10:

            adjustment -= 3

            signals.append(
                "resting_heart_rate_increasing"
            )

            recommendations.append(
                "Pay attention to recovery, sleep, "
                "stress and recent activity load."
            )


    # ========================================================
    # SPO2
    # ========================================================

    spo2_change = (
        changes["spo2"]
    )


    if spo2_change is not None:

        if spo2_change <= -3:

            adjustment -= 2

            signals.append(
                "oxygen_saturation_declining"
            )


    # ========================================================
    # WEIGHT
    # ========================================================
    #
    # We deliberately don't label weight changes as
    # automatically good or bad.
    #
    # The direction depends on the user's goal.
    #
    # Goal-specific handling comes later.
    #
    # ========================================================

    weight_change = (
        changes["weight"]
    )


    if weight_change is not None:

        if abs(weight_change) >= 5:

            signals.append(
                "weight_change_detected"
            )


    # ========================================================
    # LIMIT ADJUSTMENT
    # ========================================================

    adjustment = max(
        -MAX_ADJUSTMENT,
        min(
            MAX_ADJUSTMENT,
            adjustment
        )
    )


    # ========================================================
    # PERSONAL SCORE
    # ========================================================

    personal_score = (
        baseline_score
        +
        adjustment
    )


    personal_score = max(
        0.0,
        min(
            100.0,
            personal_score
        )
    )


    # ========================================================
    # STATUS
    # ========================================================

    if adjustment >= 5:

        status = "improving"

    elif adjustment <= -5:

        status = "declining"

    else:

        status = "stable"


    # ========================================================
    # DATA QUALITY
    # ========================================================

    available_metrics = 0

    total_metrics = 8


    metric_values = [

        activity,
        steps,
        sleep,
        heart_rate,
        resting_hr,
        weight,
        bmi,
        spo2,
    ]


    for metric in metric_values:

        if clean_values(
            metric
        ):

            available_metrics += 1


    completeness = (
        available_metrics
        /
        total_metrics
    ) * 100


    if completeness >= 75:

        data_quality = "high"

    elif completeness >= 50:

        data_quality = "moderate"

    elif completeness >= 25:

        data_quality = "low"

    else:

        data_quality = "very_low"


    # ========================================================
    # RESULT
    # ========================================================

    return {

        "personalWellnessScore":
            round(
                personal_score,
                2
            ),

        "baselineScore":
            round(
                baseline_score,
                2
            ),

        "adjustment":
            round(
                adjustment,
                2
            ),

        "status":
            status,

        "dataPoints":
            len(records),

        "trends":
            trends,

        "changes":
            changes,

        "averages":
            averages,

        "signals":
            signals,

        "recommendations":
            recommendations,

        "dataQuality":
            {

                "completeness":
                    round(
                        completeness,
                        2
                    ),

                "level":
                    data_quality,
            },
    }
from typing import Any, Dict, List, Optional

import statistics


# ============================================================
# HELPERS
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
# TREND
# ============================================================

def calculate_trend(
    values: List[float]
) -> str:

    values = [

        safe_float(value)

        for value in values
    ]


    values = [

        value

        for value in values

        if value is not None
    ]


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


    if change > 5:

        return "increasing"

    if change < -5:

        return "decreasing"

    return "stable"


# ============================================================
# TREND STRENGTH
# ============================================================

def trend_change_percent(
    values: List[float]
) -> Optional[float]:

    values = [

        safe_float(value)

        for value in values
    ]


    values = [

        value

        for value in values

        if value is not None
    ]


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
# PERSONAL WELLNESS ENGINE
# ============================================================

def analyze_wellness(
    records: List[Dict[str, Any]],
    baseline_score: float,
) -> Dict[str, Any]:

    if not records:

        return {

            "personalWellnessScore":
                round(
                    baseline_score,
                    2
                ),

            "adjustment":
                0,

            "dataPoints":
                0,

            "status":
                "insufficient_data",

            "trends": {},

            "signals": [],

            "recommendations": [],
        }


    # --------------------------------------------------------
    # Sort records by date if available
    # --------------------------------------------------------

    sorted_records = list(
        records
    )


    # ========================================================
    # Extract metrics
    # ========================================================

    activity_values = [

        record.get(
            "activity_minutes"
        )

        for record in sorted_records
    ]


    sleep_values = [

        record.get(
            "sleep_hours"
        )

        for record in sorted_records
    ]


    heart_rate_values = [

        record.get(
            "heart_rate"
        )

        for record in sorted_records
    ]


    resting_hr_values = [

        record.get(
            "resting_heart_rate"
        )

        for record in sorted_records
    ]


    weight_values = [

        record.get(
            "weight_kg"
        )

        for record in sorted_records
    ]


    spo2_values = [

        record.get(
            "spo2"
        )

        for record in sorted_records
    ]


    # ========================================================
    # Trends
    # ========================================================

    trends = {

        "activity":
            calculate_trend(
                activity_values
            ),

        "sleep":
            calculate_trend(
                sleep_values
            ),

        "heartRate":
            calculate_trend(
                heart_rate_values
            ),

        "restingHeartRate":
            calculate_trend(
                resting_hr_values
            ),

        "weight":
            calculate_trend(
                weight_values
            ),

        "spo2":
            calculate_trend(
                spo2_values
            ),
    }


    # ========================================================
    # Percentage changes
    # ========================================================

    changes = {

        "activity":
            trend_change_percent(
                activity_values
            ),

        "sleep":
            trend_change_percent(
                sleep_values
            ),

        "heartRate":
            trend_change_percent(
                heart_rate_values
            ),

        "restingHeartRate":
            trend_change_percent(
                resting_hr_values
            ),

        "weight":
            trend_change_percent(
                weight_values
            ),

        "spo2":
            trend_change_percent(
                spo2_values
            ),
    }


    # ========================================================
    # Adjustment
    # ========================================================

    adjustment = 0.0

    signals = []

    recommendations = []


    # --------------------------------------------------------
    # Activity
    # --------------------------------------------------------

    activity_change = (
        changes["activity"]
    )


    if activity_change is not None:

        if activity_change >= 10:

            adjustment += 4

            signals.append(
                "activity_improving"
            )

        elif activity_change <= -10:

            adjustment -= 4

            signals.append(
                "activity_declining"
            )

            recommendations.append(
                "Increase activity gradually "
                "and maintain consistency."
            )


    # --------------------------------------------------------
    # Sleep
    # --------------------------------------------------------

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
                "Focus on a consistent sleep "
                "schedule and adequate sleep duration."
            )


    # --------------------------------------------------------
    # Resting heart rate
    # --------------------------------------------------------

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
                "Pay attention to recovery, "
                "sleep and recent activity load."
            )


    # --------------------------------------------------------
    # SpO2
    # --------------------------------------------------------

    spo2_change = (
        changes["spo2"]
    )


    if spo2_change is not None:

        if spo2_change <= -3:

            adjustment -= 3

            signals.append(
                "spo2_declining"
            )


    # ========================================================
    # Bound adjustment
    # ========================================================

    adjustment = max(
        -15.0,
        min(
            15.0,
            adjustment
        )
    )


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
    # Summary status
    # ========================================================

    if adjustment >= 5:

        status = "improving"

    elif adjustment <= -5:

        status = "declining"

    else:

        status = "stable"


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

        "dataPoints":
            len(sorted_records),

        "status":
            status,

        "trends":
            trends,

        "changes":
            changes,

        "signals":
            signals,

        "recommendations":
            recommendations,
    }
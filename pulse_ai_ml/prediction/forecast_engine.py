from typing import Dict, Any, List

import numpy as np


# ============================================================
# CONSTANTS
# ============================================================

MIN_SCORE = 0.0
MAX_SCORE = 100.0


# Maximum allowed projected change per day.
#
# This prevents a linear regression from producing unrealistic
# long-range collapse/improvement from a small trend.
MAX_DAILY_CHANGE = 0.35


# ============================================================
# CLAMP
# ============================================================

def clamp(
    value: float,
    minimum: float = MIN_SCORE,
    maximum: float = MAX_SCORE,
) -> float:

    return max(
        minimum,
        min(
            maximum,
            float(value),
        ),
    )


# ============================================================
# ACTIVITY SCORE
# ============================================================

def activity_score(
    record: Dict[str, Any],
) -> float:

    steps = float(
        record.get(
            "steps",
            0,
        )
        or 0
    )

    score = (
        steps
        /
        10000.0
    ) * 100.0

    return clamp(score)


# ============================================================
# SLEEP SCORE
# ============================================================

def sleep_score(
    record: Dict[str, Any],
) -> float:

    sleep = float(
        record.get(
            "sleep",
            0,
        )
        or 0
    )

    if sleep <= 0:

        return 0.0

    # 8 hours is treated as the reference point.
    #
    # This is a wellness heuristic, not a clinical score.

    score = (
        100.0
        -
        (
            abs(
                sleep - 8.0
            )
            *
            18.0
        )
    )

    return clamp(score)


# ============================================================
# RECOVERY SCORE
# ============================================================

def recovery_score(
    record: Dict[str, Any],
) -> float:

    resting_hr = float(
        record.get(
            "restingHeartRate",
            0,
        )
        or 0
    )

    if resting_hr <= 0:

        return 0.0

    score = (
        100.0
        -
        max(
            0.0,
            resting_hr - 55.0,
        )
    )

    return clamp(score)


# ============================================================
# CARDIOVASCULAR SCORE
# ============================================================

def cardiovascular_score(
    record: Dict[str, Any],
) -> float:

    heart_rate = float(
        record.get(
            "heartRate",
            0,
        )
        or 0
    )

    resting_hr = float(
        record.get(
            "restingHeartRate",
            0,
        )
        or 0
    )

    scores = []

    # --------------------------------------------------------
    # Heart rate
    # --------------------------------------------------------

    if heart_rate > 0:

        if 60 <= heart_rate <= 100:

            hr_score = 100.0

        else:

            distance = min(
                abs(
                    heart_rate - 60
                ),
                abs(
                    heart_rate - 100
                ),
            )

            hr_score = clamp(
                100.0
                -
                (
                    distance * 2.0
                )
            )

        scores.append(
            hr_score
        )

    # --------------------------------------------------------
    # Resting heart rate
    # --------------------------------------------------------

    if resting_hr > 0:

        scores.append(
            recovery_score(
                record
            )
        )

    if not scores:

        return 0.0

    return clamp(
        sum(scores)
        /
        len(scores)
    )


# ============================================================
# BODY COMPOSITION SCORE
# ============================================================

def body_score(
    record: Dict[str, Any],
) -> float:

    bmi = float(
        record.get(
            "bmi",
            0,
        )
        or 0
    )

    if bmi <= 0:

        return 0.0

    if 18.5 <= bmi <= 24.9:

        return 100.0

    if 25.0 <= bmi <= 29.9:

        return 80.0

    if 17.0 <= bmi < 18.5:

        return 80.0

    if 30.0 <= bmi <= 34.9:

        return 60.0

    return 40.0


# ============================================================
# OXYGEN SCORE
# ============================================================

def oxygen_score(
    record: Dict[str, Any],
) -> float:

    oxygen = float(
        record.get(
            "oxygenSaturation",
            0,
        )
        or 0
    )

    if oxygen <= 0:

        return 0.0

    return clamp(
        oxygen
    )


# ============================================================
# DAILY WELLNESS SCORE
# ============================================================

def daily_wellness_score(
    record: Dict[str, Any],
) -> float:

    activity = activity_score(
        record
    )

    sleep = sleep_score(
        record
    )

    recovery = recovery_score(
        record
    )

    cardiovascular = (
        cardiovascular_score(
            record
        )
    )

    body = body_score(
        record
    )

    oxygen = oxygen_score(
        record
    )

    # --------------------------------------------------------
    # Match the wellness engine dimension weights
    # --------------------------------------------------------

    score = (

        activity * 0.20

        +

        sleep * 0.20

        +

        recovery * 0.20

        +

        cardiovascular * 0.20

        +

        body * 0.10

        +

        oxygen * 0.10
    )

    return round(
        clamp(score),
        2,
    )


# ============================================================
# BUILD DAILY SCORES
# ============================================================

def build_daily_scores(
    records: List[Dict[str, Any]],
) -> List[float]:

    return [
        daily_wellness_score(
            record
        )
        for record in records
    ]


# ============================================================
# CALCULATE TREND
# ============================================================

def calculate_trend(
    values: List[float],
) -> Dict[str, float]:

    if len(values) < 2:

        return {
            "slope": 0.0,
            "r2": 0.0,
        }

    x = np.arange(
        len(values),
        dtype=float,
    )

    y = np.array(
        values,
        dtype=float,
    )

    slope, intercept = np.polyfit(
        x,
        y,
        1,
    )

    predicted = (
        intercept
        +
        slope * x
    )

    ss_res = np.sum(
        (
            y - predicted
        ) ** 2
    )

    ss_tot = np.sum(
        (
            y - np.mean(y)
        ) ** 2
    )

    if ss_tot <= 0:

        r2 = 1.0

    else:

        r2 = (
            1.0
            -
            (
                ss_res
                /
                ss_tot
            )
        )

    return {
        "slope": float(slope),
        "r2": float(
            clamp(
                r2,
                0.0,
                1.0,
            )
        ),
    }


# ============================================================
# FORECAST FROM TREND
# ============================================================

def project_score(
    current: float,
    slope: float,
    days: int,
) -> float:

    # --------------------------------------------------------
    # Prevent unrealistic extrapolation
    # --------------------------------------------------------

    safe_slope = max(
        -MAX_DAILY_CHANGE,
        min(
            MAX_DAILY_CHANGE,
            slope,
        ),
    )

    projected = (
        current
        +
        (
            safe_slope
            *
            days
        )
    )

    return round(
        clamp(
            projected
        ),
        2,
    )


# ============================================================
# TRAJECTORY
# ============================================================

def determine_trajectory(
    current: float,
    forecast30: float,
) -> str:

    delta = (
        forecast30
        -
        current
    )

    if delta >= 5:

        return "strongly_improving"

    if delta >= 2:

        return "improving"

    if delta <= -5:

        return "strongly_declining"

    if delta <= -2:

        return "declining"

    return "stable"


# ============================================================
# FORECAST CONFIDENCE
# ============================================================

def calculate_forecast_confidence(
    record_count: int,
    r2: float,
) -> float:

    if record_count >= 30:
        coverage = 1.0
    else:
        coverage = min(
            1.0,
            record_count / 30.0,
        )

    trend_quality = max(
        0.0,
        min(
            1.0,
            r2,
        )
    )

    confidence = (
        coverage * 0.50
        +
        trend_quality * 0.30
        +
        0.20
    )

    # Keep forecast confidence below 95%.
    confidence = min(
        confidence,
        0.95,
    )

    return round(
        confidence * 100.0,
        1,
    )

# ============================================================
# FORECAST WELLBEING
# ============================================================

def forecast_wellbeing(
    wellness: Dict[str, Any],
    records: List[Dict[str, Any]],
) -> Dict[str, Any]:

    # ========================================================
    # NO DATA
    # ========================================================

    if not records:

        current = clamp(
            float(
                wellness.get(
                    "personalWellnessScore",
                    0.0,
                )
            )
        )

        return {

            "current":
                round(
                    current,
                    2,
                ),

            "forecast7d":
                round(
                    current,
                    2,
                ),

            "forecast14d":
                round(
                    current,
                    2,
                ),

            "forecast30d":
                round(
                    current,
                    2,
                ),

            "trajectory":
                "unknown",

            "confidence":
                0.0,
        }


    # ========================================================
    # SORT CHRONOLOGICALLY
    # ========================================================

    records = sorted(
        records,
        key=lambda record:
            str(
                record.get(
                    "date",
                    "",
                )
            ),
    )


    # ========================================================
    # DAILY WELLNESS SCORES
    # ========================================================

    daily_scores = (
        build_daily_scores(
            records
        )
    )


    # ========================================================
    # CURRENT WELLNESS
    # ========================================================

    current = clamp(
        float(
            wellness.get(
                "personalWellnessScore",
                daily_scores[-1],
            )
        )
    )


    # ========================================================
    # RECENT TREND
    #
    # Give more importance to recent behavior.
    # ========================================================

    if len(daily_scores) >= 14:

        trend_values = (
            daily_scores[-14:]
        )

    else:

        trend_values = (
            daily_scores
        )


    trend = calculate_trend(
        trend_values
    )

    slope = trend[
        "slope"
    ]

    r2 = trend[
        "r2"
    ]


    # ========================================================
    # FORECAST
    # ========================================================

    forecast7 = project_score(
        current,
        slope,
        7,
    )

    forecast14 = project_score(
        current,
        slope,
        14,
    )

    forecast30 = project_score(
        current,
        slope,
        30,
    )


    # ========================================================
    # TRAJECTORY
    # ========================================================

    trajectory = (
        determine_trajectory(
            current,
            forecast30,
        )
    )


    # ========================================================
    # CONFIDENCE
    # ========================================================

    confidence = (
        calculate_forecast_confidence(
            len(records),
            r2,
        )
    )


    # ========================================================
    # RESULT
    # ========================================================

    return {

        "current":
            round(
                current,
                2,
            ),

        "forecast7d":
            forecast7,

        "forecast14d":
            forecast14,

        "forecast30d":
            forecast30,

        "trajectory":
            trajectory,

        "confidence":
            confidence,

        # ----------------------------------------------------
        # Additional transparent metadata
        # ----------------------------------------------------

        "trendSlope":
            round(
                slope,
                4,
            ),

        "trendR2":
            round(
                r2,
                4,
            ),

        "recordsUsed":
            len(records),
    }
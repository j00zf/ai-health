from typing import Dict, Any, List

import numpy as np


# ============================================================
# CLAMP
# ============================================================

def clamp(
    value: float,
    minimum: float = 0.0,
    maximum: float = 100.0,
) -> float:

    return max(
        minimum,
        min(
            maximum,
            float(value),
        ),
    )


# ============================================================
# SIMPLE LINEAR FORECAST
# ============================================================

def linear_forecast(
    values: List[float],
    days: int,
) -> float:

    if not values:

        return 0.0


    if len(values) < 2:

        return round(
            float(values[-1]),
            2,
        )


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


    future_x = (
        len(values) - 1
        + days
    )


    prediction = (
        intercept
        +
        slope * future_x
    )


    return round(
        clamp(
            prediction
        ),
        2,
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


    # 10,000 steps = 100
    score = (
        steps
        /
        10000.0
    ) * 100.0


    return clamp(
        score
    )


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


    # 7–9 hours treated as excellent.
    #
    # 8 hours is the center.
    # Every hour away reduces the score.
    score = (
        100.0
        -
        (
            abs(
                sleep
                -
                8.0
            )
            *
            18.0
        )
    )


    return clamp(
        score
    )


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


    # Lower resting HR is generally associated
    # with better recovery, but this is only
    # a wellness scoring heuristic.
    score = (
        100.0
        -
        (
            max(
                0.0,
                resting_hr
                -
                55.0,
            )
        )
    )


    return clamp(
        score
    )


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


    if (
        heart_rate <= 0
        and
        resting_hr <= 0
    ):

        return 0.0


    scores = []


    if heart_rate > 0:

        # Broad wellness range heuristic.
        if 60 <= heart_rate <= 100:

            hr_score = 100.0

        else:

            distance = min(
                abs(
                    heart_rate
                    -
                    60
                ),
                abs(
                    heart_rate
                    -
                    100
                ),
            )

            hr_score = clamp(
                100.0
                -
                (
                    distance
                    *
                    2.0
                )
            )

        scores.append(
            hr_score
        )


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


    # General wellness heuristic.
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
    # Same dimension structure used by wellness engine
    # --------------------------------------------------------

    score = (

        activity
        *
        0.20

        +

        sleep
        *
        0.20

        +

        recovery
        *
        0.20

        +

        cardiovascular
        *
        0.20

        +

        body
        *
        0.10

        +

        oxygen
        *
        0.10

    )


    return round(
        clamp(
            score
        ),
        2,
    )


# ============================================================
# BUILD FORECAST
# ============================================================

def forecast_wellbeing(
    wellness: Dict[str, Any],
    records: List[Dict[str, Any]],
) -> Dict[str, Any]:

    # ========================================================
    # NO RECORDS
    # ========================================================

    if not records:

        current = clamp(
            float(
                wellness.get(
                    "personalWellnessScore",
                    0,
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
    # DAILY SCORES
    # ========================================================

    daily_scores = []


    for record in records:

        score = (
            daily_wellness_score(
                record
            )
        )

        daily_scores.append(
            score
        )


    # ========================================================
    # CURRENT SCORE
    # ========================================================

    #
    # Use the actual wellness engine score as the current
    # reference point.
    #

    current = clamp(
        float(
            wellness.get(
                "personalWellnessScore",
                daily_scores[-1],
            )
        )
    )


    # ========================================================
    # FUTURE FORECASTS
    # ========================================================

    forecast7 = linear_forecast(
        daily_scores,
        7,
    )

    forecast14 = linear_forecast(
        daily_scores,
        14,
    )

    forecast30 = linear_forecast(
        daily_scores,
        30,
    )


    # ========================================================
    # TRAJECTORY
    # ========================================================

    delta = (
        forecast30
        -
        current
    )


    if delta >= 5:

        trajectory = (
            "strongly_improving"
        )

    elif delta >= 2:

        trajectory = (
            "improving"
        )

    elif delta <= -5:

        trajectory = (
            "strongly_declining"
        )

    elif delta <= -2:

        trajectory = (
            "declining"
        )

    else:

        trajectory = (
            "stable"
        )


    # ========================================================
    # DATA-BASED CONFIDENCE
    # ========================================================

    record_count = len(
        records
    )


    confidence = min(
        100.0,
        record_count
        *
        3.33,
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
            round(
                clamp(
                    forecast7
                ),
                2,
            ),

        "forecast14d":
            round(
                clamp(
                    forecast14
                ),
                2,
            ),

        "forecast30d":
            round(
                clamp(
                    forecast30
                ),
                2,
            ),

        "trajectory":
            trajectory,

        "confidence":
            round(
                confidence,
                1,
            ),
    }
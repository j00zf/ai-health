from typing import Any, Dict, List, Optional
import statistics


# ============================================================
# CONFIGURATION
# ============================================================

WINDOW_7 = 7
WINDOW_14 = 14
WINDOW_30 = 30

MIN_POINTS_FOR_TREND = 3


# Dimension weights
ACTIVITY_WEIGHT = 0.20
SLEEP_WEIGHT = 0.20
RECOVERY_WEIGHT = 0.20
CARDIO_WEIGHT = 0.20
BODY_WEIGHT = 0.10
OXYGEN_WEIGHT = 0.10


# ML baseline / longitudinal blend
ML_BASELINE_WEIGHT = 0.40
LONGITUDINAL_WEIGHT = 0.60


# ============================================================
# SAFE NUMBER
# ============================================================

def safe_float(value: Any) -> Optional[float]:

    if value is None:
        return None

    try:
        value = float(value)

        if value != value:
            return None

        return value

    except (TypeError, ValueError):

        return None


# ============================================================
# CLEAN VALUES
# ============================================================

def clean_values(
    values: List[Any]
) -> List[float]:

    result = []

    for value in values:

        number = safe_float(value)

        if number is not None:
            result.append(number)

    return result


# ============================================================
# AVERAGE
# ============================================================

def average(
    values: List[Any]
) -> Optional[float]:

    values = clean_values(values)

    if not values:
        return None

    return round(
        statistics.mean(values),
        2
    )


# ============================================================
# MEDIAN
# ============================================================

def median(
    values: List[Any]
) -> Optional[float]:

    values = clean_values(values)

    if not values:
        return None

    return round(
        statistics.median(values),
        2
    )


# ============================================================
# PERCENT CHANGE
# ============================================================

def percent_change(
    old: Optional[float],
    new: Optional[float]
) -> Optional[float]:

    if old is None or new is None:
        return None

    if old == 0:
        return None

    return round(
        ((new - old) / abs(old)) * 100,
        2
    )


# ============================================================
# WINDOW
# ============================================================

def get_window(
    records: List[Dict[str, Any]],
    days: int
) -> List[Dict[str, Any]]:

    if not records:
        return []

    return records[-days:]


# ============================================================
# WINDOW AVERAGE
# ============================================================

def window_average(
    records: List[Dict[str, Any]],
    field: str
) -> Optional[float]:

    values = [

        record.get(field)

        for record in records

    ]

    return average(values)


# ============================================================
# TREND SCORE
# ============================================================
#
# Compares:
#
# recent 7-day average
#
# against
#
# previous available baseline.
#
# Returns:
#
# -100 → strongly unfavorable
#    0 → neutral
# +100 → strongly favorable
#
# ============================================================

def calculate_improvement_score(
    baseline: Optional[float],
    recent: Optional[float],
    direction: str,
    sensitivity: float = 1.0
) -> float:

    if baseline is None or recent is None:

        return 0.0

    if baseline == 0:

        return 0.0

    change = (
        (recent - baseline)
        /
        abs(baseline)
    ) * 100.0


    # --------------------------------------------------------
    # For metrics where higher is better
    # --------------------------------------------------------

    if direction == "higher_better":

        impact = change


    # --------------------------------------------------------
    # For metrics where lower is generally better
    #
    # Example:
    # resting heart rate
    #
    # --------------------------------------------------------

    elif direction == "lower_better":

        impact = -change


    else:

        impact = 0.0


    impact *= sensitivity


    # Limit contribution
    impact = max(
        -20.0,
        min(
            20.0,
            impact
        )
    )


    return round(
        impact,
        2
    )


# ============================================================
# CONSISTENCY SCORE
# ============================================================

def calculate_consistency(
    values: List[Any]
) -> float:

    values = clean_values(values)

    if len(values) < 3:
        return 50.0

    mean_value = statistics.mean(values)

    if mean_value == 0:
        return 50.0

    std = statistics.stdev(values)

    coefficient = (
        std /
        abs(mean_value)
    )

    # Lower variability → higher consistency
    score = 100.0 - (
        coefficient * 100.0
    )

    return round(
        max(
            0.0,
            min(
                100.0,
                score
            )
        ),
        2
    )


# ============================================================
# SLEEP SCORE
# ============================================================

def sleep_score(
    recent_records: List[Dict[str, Any]]
) -> float:

    values = [

        safe_float(
            record.get(
                "sleep_hours"
            )
        )

        for record in recent_records
    ]

    values = [
        value
        for value in values
        if value is not None
    ]


    if not values:

        return 50.0


    avg_sleep = statistics.mean(
        values
    )


    # --------------------------------------------------------
    # General wellness-oriented sleep range.
    #
    # This is NOT a clinical sleep diagnosis.
    # --------------------------------------------------------

    if 7.0 <= avg_sleep <= 9.0:

        base = 100.0

    elif 6.0 <= avg_sleep < 7.0:

        base = 80.0

    elif 9.0 < avg_sleep <= 10.0:

        base = 85.0

    elif 5.0 <= avg_sleep < 6.0:

        base = 60.0

    elif 10.0 < avg_sleep <= 11.0:

        base = 65.0

    else:

        base = 40.0


    consistency = calculate_consistency(
        values
    )


    return round(
        (
            base * 0.75
            +
            consistency * 0.25
        ),
        2
    )


# ============================================================
# ACTIVITY SCORE
# ============================================================

def activity_score(
    recent_records: List[Dict[str, Any]]
) -> float:

    activity = [

        safe_float(
            record.get(
                "activity_minutes"
            )
        )

        for record in recent_records
    ]


    steps = [

        safe_float(
            record.get(
                "steps"
            )
        )

        for record in recent_records
    ]


    activity = [
        x for x in activity
        if x is not None
    ]


    steps = [
        x for x in steps
        if x is not None
    ]


    scores = []


    # --------------------------------------------------------
    # Activity
    # --------------------------------------------------------

    if activity:

        avg_activity = statistics.mean(
            activity
        )

        # Approximate wellness scoring.
        # This is not a medical guideline.

        if avg_activity >= 150:
            scores.append(100)

        elif avg_activity >= 120:
            scores.append(90)

        elif avg_activity >= 90:
            scores.append(80)

        elif avg_activity >= 60:
            scores.append(70)

        elif avg_activity >= 30:
            scores.append(55)

        else:
            scores.append(40)


    # --------------------------------------------------------
    # Steps
    # --------------------------------------------------------

    if steps:

        avg_steps = statistics.mean(
            steps
        )

        if avg_steps >= 10000:
            scores.append(100)

        elif avg_steps >= 8000:
            scores.append(90)

        elif avg_steps >= 6000:
            scores.append(80)

        elif avg_steps >= 4000:
            scores.append(70)

        elif avg_steps >= 2000:
            scores.append(55)

        else:
            scores.append(40)


    if not scores:

        return 50.0


    return round(
        statistics.mean(scores),
        2
    )


# ============================================================
# RECOVERY SCORE
# ============================================================

def recovery_score(
    recent_records: List[Dict[str, Any]]
) -> float:

    scores = []


    resting_hr = [

        safe_float(
            record.get(
                "resting_heart_rate"
            )
        )

        for record in recent_records
    ]


    resting_hr = [
        x for x in resting_hr
        if x is not None
    ]


    if resting_hr:

        avg_hr = statistics.mean(
            resting_hr
        )


        # Used only as a wellness-oriented
        # scoring heuristic.

        if 50 <= avg_hr <= 70:

            scores.append(95)

        elif 70 < avg_hr <= 80:

            scores.append(80)

        elif 80 < avg_hr <= 90:

            scores.append(65)

        else:

            scores.append(50)


        consistency = calculate_consistency(
            resting_hr
        )

        scores.append(
            consistency
        )


    if not scores:

        return 50.0


    return round(
        statistics.mean(scores),
        2
    )


# ============================================================
# CARDIO SCORE
# ============================================================

def cardio_score(
    recent_records: List[Dict[str, Any]]
) -> float:

    scores = []


    heart_rate = [

        safe_float(
            record.get(
                "heart_rate"
            )
        )

        for record in recent_records
    ]


    resting_hr = [

        safe_float(
            record.get(
                "resting_heart_rate"
            )
        )

        for record in recent_records
    ]


    heart_rate = [
        x for x in heart_rate
        if x is not None
    ]


    resting_hr = [
        x for x in resting_hr
        if x is not None
    ]


    if heart_rate:

        avg_hr = statistics.mean(
            heart_rate
        )


        if 55 <= avg_hr <= 85:

            scores.append(95)

        elif 85 < avg_hr <= 100:

            scores.append(80)

        elif 100 < avg_hr <= 120:

            scores.append(65)

        else:

            scores.append(50)


    if resting_hr:

        avg_resting = statistics.mean(
            resting_hr
        )


        if 50 <= avg_resting <= 70:

            scores.append(95)

        elif 70 < avg_resting <= 80:

            scores.append(80)

        elif 80 < avg_resting <= 90:

            scores.append(65)

        else:

            scores.append(50)


    if not scores:

        return 50.0


    return round(
        statistics.mean(scores),
        2
    )


# ============================================================
# BODY SCORE
# ============================================================

def body_score(
    recent_records: List[Dict[str, Any]]
) -> float:

    bmi_values = [

        safe_float(
            record.get(
                "bmi"
            )
        )

        for record in recent_records
    ]


    bmi_values = [
        x for x in bmi_values
        if x is not None
    ]


    if not bmi_values:

        return 50.0


    avg_bmi = statistics.mean(
        bmi_values
    )


    # Wellness-oriented population heuristic.
    # Not a diagnostic classification.

    if 18.5 <= avg_bmi < 25:

        return 100.0

    elif 25 <= avg_bmi < 30:

        return 80.0

    elif 30 <= avg_bmi < 35:

        return 65.0

    elif 17 <= avg_bmi < 18.5:

        return 75.0

    else:

        return 50.0


# ============================================================
# OXYGEN SCORE
# ============================================================

def oxygen_score(
    recent_records: List[Dict[str, Any]]
) -> float:

    values = [

        safe_float(
            record.get(
                "spo2"
            )
        )

        for record in recent_records
    ]


    values = [
        x for x in values
        if x is not None
    ]


    if not values:

        return 50.0


    avg_spo2 = statistics.mean(
        values
    )


    if avg_spo2 >= 97:

        return 100.0

    elif avg_spo2 >= 95:

        return 90.0

    elif avg_spo2 >= 92:

        return 70.0

    else:

        return 50.0


# ============================================================
# DIMENSION SCORES
# ============================================================

def calculate_dimension_scores(
    recent_records: List[Dict[str, Any]]
) -> Dict[str, float]:

    return {

        "activity":
            activity_score(
                recent_records
            ),

        "sleep":
            sleep_score(
                recent_records
            ),

        "recovery":
            recovery_score(
                recent_records
            ),

        "cardiovascular":
            cardio_score(
                recent_records
            ),

        "body":
            body_score(
                recent_records
            ),

        "oxygen":
            oxygen_score(
                recent_records
            ),
    }


# ============================================================
# WEIGHTED LONGITUDINAL SCORE
# ============================================================

def calculate_longitudinal_score(
    dimensions: Dict[str, float]
) -> float:

    score = (

        dimensions["activity"]
        * ACTIVITY_WEIGHT

        +

        dimensions["sleep"]
        * SLEEP_WEIGHT

        +

        dimensions["recovery"]
        * RECOVERY_WEIGHT

        +

        dimensions["cardiovascular"]
        * CARDIO_WEIGHT

        +

        dimensions["body"]
        * BODY_WEIGHT

        +

        dimensions["oxygen"]
        * OXYGEN_WEIGHT
    )


    return round(
        score,
        2
    )


# ============================================================
# 7 / 14 / 30 ANALYSIS
# ============================================================

def analyze_windows(
    records: List[Dict[str, Any]]
) -> Dict[str, Any]:

    window_7 = get_window(
        records,
        WINDOW_7
    )

    window_14 = get_window(
        records,
        WINDOW_14
    )

    window_30 = get_window(
        records,
        WINDOW_30
    )


    scores_7 = calculate_dimension_scores(
        window_7
    )

    scores_14 = calculate_dimension_scores(
        window_14
    )

    scores_30 = calculate_dimension_scores(
        window_30
    )


    total_7 = calculate_longitudinal_score(
        scores_7
    )

    total_14 = calculate_longitudinal_score(
        scores_14
    )

    total_30 = calculate_longitudinal_score(
        scores_30
    )


    return {

        "7d": {

            "records":
                len(window_7),

            "dimensions":
                scores_7,

            "score":
                total_7,
        },

        "14d": {

            "records":
                len(window_14),

            "dimensions":
                scores_14,

            "score":
                total_14,
        },

        "30d": {

            "records":
                len(window_30),

            "dimensions":
                scores_30,

            "score":
                total_30,
        },
    }


# ============================================================
# TREND DIRECTION
# ============================================================

def determine_trend(
    score_7: float,
    score_14: float,
    score_30: float
) -> str:

    recent_vs_14 = (
        score_7
        -
        score_14
    )


    recent_vs_30 = (
        score_7
        -
        score_30
    )


    if (
        recent_vs_14 >= 3
        and
        recent_vs_30 >= 3
    ):

        return "improving"


    if (
        recent_vs_14 <= -3
        and
        recent_vs_30 <= -3
    ):

        return "declining"


    return "stable"


# ============================================================
# DATA QUALITY
# ============================================================

def calculate_data_quality(
    records: List[Dict[str, Any]]
) -> Dict[str, Any]:

    if not records:

        return {

            "recordCount":
                0,

            "completeness":
                0.0,

            "recency":
                0.0,

            "confidence":
                0.0,

            "level":
                "very_low",
        }


    important_fields = [

        "steps",
        "activity_minutes",
        "sleep_hours",
        "heart_rate",
        "resting_heart_rate",
        "weight_kg",
        "bmi",
        "spo2",
    ]


    total = (
        len(records)
        *
        len(important_fields)
    )


    available = 0


    for record in records:

        for field in important_fields:

            if safe_float(
                record.get(field)
            ) is not None:

                available += 1


    completeness = (
        available
        /
        total
    ) * 100


    # --------------------------------------------------------
    # Recency proxy
    #
    # We use record coverage as a simple first version.
    # Date-aware recency can be added when the production
    # record schema is finalized.
    # --------------------------------------------------------

    if len(records) >= 30:

        recency = 100.0

    elif len(records) >= 14:

        recency = 85.0

    elif len(records) >= 7:

        recency = 70.0

    elif len(records) >= 3:

        recency = 50.0

    else:

        recency = 25.0


    confidence = (
        completeness * 0.70
        +
        recency * 0.30
    )


    if confidence >= 85:

        level = "high"

    elif confidence >= 65:

        level = "moderate"

    elif confidence >= 40:

        level = "low"

    else:

        level = "very_low"


    return {

        "recordCount":
            len(records),

        "completeness":
            round(
                completeness,
                2
            ),

        "recency":
            recency,

        "confidence":
            round(
                confidence,
                2
            ),

        "level":
            level,
    }


# ============================================================
# SIGNALS
# ============================================================

def generate_signals(
    windows: Dict[str, Any]
) -> List[Dict[str, Any]]:

    signals = []


    recent = windows["7d"]["dimensions"]

    medium = windows["14d"]["dimensions"]

    long = windows["30d"]["dimensions"]


    for dimension in recent:

        recent_score = recent[
            dimension
        ]

        medium_score = medium[
            dimension
        ]

        long_score = long[
            dimension
        ]


        if (
            recent_score >= medium_score + 5
            and
            recent_score >= long_score + 5
        ):

            signals.append({

                "dimension":
                    dimension,

                "direction":
                    "improving",

                "strength":
                    round(
                        recent_score
                        -
                        max(
                            medium_score,
                            long_score
                        ),
                        2
                    ),
            })


        elif (
            recent_score <= medium_score - 5
            and
            recent_score <= long_score - 5
        ):

            signals.append({

                "dimension":
                    dimension,

                "direction":
                    "declining",

                "strength":
                    round(
                        min(
                            medium_score,
                            long_score
                        )
                        -
                        recent_score,
                        2
                    ),
            })


    return signals


# ============================================================
# MAIN WELLNESS ANALYSIS
# ============================================================

def analyze_wellness(
    records: List[Dict[str, Any]],
    baseline_score: float,
) -> Dict[str, Any]:

    if not records:

        return {

            "baselineScore":
                round(
                    baseline_score,
                    2
                ),

            "longitudinalScore":
                None,

            "personalWellnessScore":
                round(
                    baseline_score,
                    2
                ),

            "status":
                "insufficient_data",

            "windows":
                {},

            "signals":
                [],

            "dataQuality":
                calculate_data_quality(
                    []
                ),
        }


    # --------------------------------------------------------
    # Windows
    # --------------------------------------------------------

    windows = analyze_windows(
        records
    )


    score_7 = (
        windows["7d"]["score"]
    )

    score_14 = (
        windows["14d"]["score"]
    )

    score_30 = (
        windows["30d"]["score"]
    )


    # --------------------------------------------------------
    # Choose longitudinal score
    #
    # More recent data receives more weight.
    # --------------------------------------------------------

    longitudinal_score = (

        score_7 * 0.50

        +

        score_14 * 0.30

        +

        score_30 * 0.20
    )


    longitudinal_score = round(
        longitudinal_score,
        2
    )


    # --------------------------------------------------------
    # Blend ML baseline + longitudinal score
    # --------------------------------------------------------

    personal_wellness = (

        baseline_score
        *
        ML_BASELINE_WEIGHT

        +

        longitudinal_score
        *
        LONGITUDINAL_WEIGHT
    )


    personal_wellness = round(
        personal_wellness,
        2
    )


    # --------------------------------------------------------
    # Trend
    # --------------------------------------------------------

    status = determine_trend(

        score_7,

        score_14,

        score_30
    )


    # --------------------------------------------------------
    # Signals
    # --------------------------------------------------------

    signals = generate_signals(
        windows
    )


    # --------------------------------------------------------
    # Data quality
    # --------------------------------------------------------

    data_quality = (
        calculate_data_quality(
            records
        )
    )


    # --------------------------------------------------------
    # Return
    # --------------------------------------------------------

    return {

        "baselineScore":
            round(
                baseline_score,
                2
            ),

        "longitudinalScore":
            longitudinal_score,

        "personalWellnessScore":
            personal_wellness,

        "status":
            status,

        "windows":
            windows,

        "signals":
            signals,

        "dataQuality":
            data_quality,

        "method":
            {

                "mlBaselineWeight":
                    ML_BASELINE_WEIGHT,

                "longitudinalWeight":
                    LONGITUDINAL_WEIGHT,

                "windowWeights":
                    {

                        "7d":
                            0.50,

                        "14d":
                            0.30,

                        "30d":
                            0.20,
                    },

                "dimensionWeights":
                    {

                        "activity":
                            ACTIVITY_WEIGHT,

                        "sleep":
                            SLEEP_WEIGHT,

                        "recovery":
                            RECOVERY_WEIGHT,

                        "cardiovascular":
                            CARDIO_WEIGHT,

                        "body":
                            BODY_WEIGHT,

                        "oxygen":
                            OXYGEN_WEIGHT,
                    },
            },
    }
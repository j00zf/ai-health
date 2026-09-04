from typing import Any, Dict, Optional


# ============================================================
# SAFE NUMBER
# ============================================================

def number(
    value: Any
) -> Optional[float]:

    if value is None:
        return None

    try:
        return float(value)

    except (
        TypeError,
        ValueError
    ):
        return None


# ============================================================
# GET NESTED VALUE
# ============================================================

def nested(
    data: Dict[str, Any],
    *keys
) -> Any:

    current = data

    for key in keys:

        if not isinstance(
            current,
            dict
        ):
            return None

        current = current.get(
            key
        )

    return current


# ============================================================
# PULSE RECORD → WELLNESS RECORD
# ============================================================

def adapt_health_record(
    record: Dict[str, Any]
) -> Dict[str, Any]:

    # --------------------------------------------------------
    # Activity
    # --------------------------------------------------------

    steps = number(
        record.get(
            "steps"
        )
    )


    active_hours = number(
        record.get(
            "activeHours"
        )
    )


    active_zone_minutes = number(
        record.get(
            "activeZoneMinutes"
        )
    )


    # Prefer active-zone minutes.
    #
    # If unavailable, use active hours.
    #
    activity_minutes = (
        active_zone_minutes
        if active_zone_minutes is not None
        else (
            active_hours * 60
            if active_hours is not None
            else None
        )
    )


    # --------------------------------------------------------
    # Heart
    # --------------------------------------------------------

    heart_rate = number(
        record.get(
            "heartRate"
        )
    )


    resting_heart_rate = number(
        record.get(
            "restingHeartRate"
        )
    )


    # --------------------------------------------------------
    # Sleep
    # --------------------------------------------------------

    sleep_hours = number(
        record.get(
            "sleepHours"
        )
    )


    # --------------------------------------------------------
    # Weight
    # --------------------------------------------------------

    weight = number(
        record.get(
            "weight"
        )
    )


    bmi = number(
        record.get(
            "bmi"
        )
    )


    # --------------------------------------------------------
    # Oxygen
    # --------------------------------------------------------

    spo2 = number(
        record.get(
            "bloodOxygen"
        )
    )


    # --------------------------------------------------------
    # Calories
    # --------------------------------------------------------

    calories = number(
        record.get(
            "calories"
        )
    )


    # --------------------------------------------------------
    # Distance
    # --------------------------------------------------------

    distance = number(
        record.get(
            "distanceWalked"
        )
    )


    # --------------------------------------------------------
    # Return normalized record
    # --------------------------------------------------------

    return {

        "date":
            record.get(
                "date"
            ),

        "steps":
            steps,

        "activity_minutes":
            activity_minutes,

        "active_hours":
            active_hours,

        "active_zone_minutes":
            active_zone_minutes,

        "heart_rate":
            heart_rate,

        "resting_heart_rate":
            resting_heart_rate,

        "sleep_hours":
            sleep_hours,

        "weight_kg":
            weight,

        "bmi":
            bmi,

        "spo2":
            spo2,

        "calories":
            calories,

        "distance":
            distance,
    }


# ============================================================
# ADAPT MULTIPLE RECORDS
# ============================================================

def adapt_health_records(
    records
) -> list:

    if not records:
        return []


    return [

        adapt_health_record(
            record
        )

        for record in records
    ]
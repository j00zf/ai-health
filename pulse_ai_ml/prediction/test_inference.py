from prediction.inference import analyze_user


def main():

    # ========================================================
    # SAMPLE USER PROFILE
    # ========================================================

    profile = {

        "age":
            25,

        "sex":
            1,

        "height_cm":
            175,

        "weight_kg":
            70,

        "bmi":
            22.86,

        "waist_cm":
            80,

        "heart_rate":
            72,

        "activity_minutes":
            180,

        "sleep_hours":
            7.5,

        "smoking":
            0,

        "alcohol":
            0,
    }


    # ========================================================
    # SAMPLE LONGITUDINAL HEALTH DATA
    # ========================================================

    health_records = [

        {
            "date": "2026-08-01",

            "steps": 6000,

            "activeHours": 1.4,

            "activeZoneMinutes": 35,

            "heartRate": 75,

            "restingHeartRate": 68,

            "sleep": 6.8,

            "weight": 70.5,

            "bmi": 23.0,

            "oxygenSaturation": 97,

            "calories": 2100,

            "distance": 4.2,
        },


        {
            "date": "2026-08-08",

            "steps": 6800,

            "activeHours": 1.5,

            "activeZoneMinutes": 40,

            "heartRate": 74,

            "restingHeartRate": 67,

            "sleep": 7.1,

            "weight": 70.2,

            "bmi": 22.9,

            "oxygenSaturation": 98,

            "calories": 2150,

            "distance": 4.6,
        },


        {
            "date": "2026-08-15",

            "steps": 7500,

            "activeHours": 1.7,

            "activeZoneMinutes": 48,

            "heartRate": 73,

            "restingHeartRate": 65,

            "sleep": 7.5,

            "weight": 70.0,

            "bmi": 22.86,

            "oxygenSaturation": 98,

            "calories": 2200,

            "distance": 5.1,
        },


        {
            "date": "2026-08-22",

            "steps": 8100,

            "activeHours": 1.9,

            "activeZoneMinutes": 55,

            "heartRate": 72,

            "restingHeartRate": 64,

            "sleep": 7.8,

            "weight": 69.8,

            "bmi": 22.8,

            "oxygenSaturation": 98,

            "calories": 2250,

            "distance": 5.6,
        },
    ]


    # ========================================================
    # ANALYZE
    # ========================================================

    result = analyze_user(

        profile,

        health_records
    )


    # ========================================================
    # DISPLAY
    # ========================================================

    print(
        "\n"
        + "=" * 70
    )

    print(
        "PULSE AI COMPLETE WELLBEING ANALYSIS"
    )

    print(
        "=" * 70
    )


    print(
        "\nSCORES"
    )


    print(
        "-" * 70
    )


    for key, value in (
        result["scores"].items()
    ):

        print(
            f"{key:30} : {value}"
        )


    print(
        "\nPERSONAL WELLNESS"
    )


    print(
        "-" * 70
    )


    print(
        "Status:",
        result[
            "personalWellness"
        ]["status"]
    )


    print(
        "Adjustment:",
        result[
            "personalWellness"
        ]["adjustment"]
    )


    print(
        "Signals:"
    )


    for signal in (
        result[
            "personalWellness"
        ]["signals"]
    ):

        print(
            f"  • {signal}"
        )


    print(
        "\nTRENDS"
    )


    print(
        "-" * 70
    )


    for key, value in (
        result[
            "personalWellness"
        ]["trends"].items()
    ):

        print(
            f"{key:25} : {value}"
        )


    print(
        "\nDATA QUALITY"
    )


    print(
        "-" * 70
    )


    print(
        result[
            "dataQuality"
        ]
    )


    print(
        "\nRECOMMENDATIONS"
    )


    print(
        "-" * 70
    )


    for recommendation in (
        result[
            "personalWellness"
        ]["recommendations"]
    ):

        print(
            f"  • {recommendation}"
        )


if __name__ == "__main__":

    main()
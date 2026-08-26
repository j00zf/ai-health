from prediction.inference import analyze_user


def main():

    # ========================================================
    # SAMPLE USER PROFILE
    # ========================================================

    profile = {

        "age": 25,

        "sex": 1,

        "height_cm": 175,

        "weight_kg": 70,

        "bmi": 22.86,

        "waist_cm": 80,

        "heart_rate": 72,

        "activity_minutes": 180,

        "sleep_hours": 7.5,

        "smoking": 0,

        "alcohol": 0,
    }


    # ========================================================
    # SAMPLE LONGITUDINAL HEALTH DATA
    # ========================================================

    health_records = []


    # ========================================================
    # CREATE 30 DAYS OF SAMPLE DATA
    # ========================================================

    for day in range(1, 31):

        progress = day / 30.0


        # ----------------------------------------------------
        # Activity gradually improves
        # ----------------------------------------------------

        steps = (
            5500
            +
            int(
                3000 * progress
            )
        )


        active_zone = (
            30
            +
            int(
                30 * progress
            )
        )


        active_hours = (
            1.2
            +
            (
                0.8 * progress
            )
        )


        # ----------------------------------------------------
        # Sleep gradually improves
        # ----------------------------------------------------

        sleep = (
            6.7
            +
            (
                1.0 * progress
            )
        )


        # ----------------------------------------------------
        # Resting HR gradually decreases
        # ----------------------------------------------------

        resting_hr = (
            69
            -
            (
                5 * progress
            )
        )


        # ----------------------------------------------------
        # Heart rate remains stable
        # ----------------------------------------------------

        heart_rate = 73


        # ----------------------------------------------------
        # Weight remains relatively stable
        # ----------------------------------------------------

        weight = (
            70.5
            -
            (
                0.5 * progress
            )
        )


        # ----------------------------------------------------
        # BMI remains relatively stable
        # ----------------------------------------------------

        bmi = (
            22.95
            -
            (
                0.15 * progress
            )
        )


        # ----------------------------------------------------
        # Add daily record
        # ----------------------------------------------------

        health_records.append({

            "date":
                f"2026-08-{day:02d}",

            "steps":
                steps,

            "activeHours":
                round(
                    active_hours,
                    2
                ),

            "activeZoneMinutes":
                active_zone,

            "heartRate":
                heart_rate,

            "restingHeartRate":
                round(
                    resting_hr,
                    2
                ),

            "sleep":
                round(
                    sleep,
                    2
                ),

            "weight":
                round(
                    weight,
                    2
                ),

            "bmi":
                round(
                    bmi,
                    2
                ),

            "oxygenSaturation":
                98,

            "calories":
                2200 + (
                    day * 5
                ),

            "distance":
                4.5 + (
                    day * 0.04
                ),
        })


    # ========================================================
    # ANALYZE USER
    # ========================================================

    result = analyze_user(

        profile,

        health_records
    )


    # ========================================================
    # DISPLAY HEADER
    # ========================================================

    print()

    print(
        "=" * 70
    )

    print(
        "PULSE AI COMPLETE WELLBEING ANALYSIS"
    )

    print(
        "=" * 70
    )


    # ========================================================
    # SCORES
    # ========================================================

    print()

    print(
        "SCORES"
    )

    print(
        "-" * 70
    )


    for key, value in (
        result["scores"].items()
    ):

        print(
            f"{key:35} : {value}"
        )


    # ========================================================
    # MODEL PROBABILITIES
    # ========================================================

    print()

    print(
        "MODEL PROBABILITIES"
    )

    print(
        "-" * 70
    )


    for key, value in (
        result[
            "modelProbabilities"
        ].items()
    ):

        print(
            f"{key:35} : {value}"
        )


    # ========================================================
    # WELLNESS STATUS
    # ========================================================

    wellness = result[
        "wellness"
    ]


    print()

    print(
        "PERSONAL WELLNESS"
    )

    print(
        "-" * 70
    )


    print(
        f"{'Status':35} : "
        f"{wellness['status']}"
    )


    print(
        f"{'Baseline Score':35} : "
        f"{wellness['baselineScore']}"
    )


    print(
        f"{'Longitudinal Score':35} : "
        f"{wellness['longitudinalScore']}"
    )


    print(
        f"{'Personal Wellness Score':35} : "
        f"{wellness['personalWellnessScore']}"
    )


    # ========================================================
    # 7 / 14 / 30 DAY WINDOWS
    # ========================================================

    print()

    print(
        "LONGITUDINAL WINDOWS"
    )

    print(
        "-" * 70
    )


    windows = wellness[
        "windows"
    ]


    for window_name in [
        "7d",
        "14d",
        "30d",
    ]:

        window = windows[
            window_name
        ]


        print()

        print(
            f"{window_name.upper()} "
            f"({window['records']} records)"
        )


        print(
            f"  Overall Score : "
            f"{window['score']}"
        )


        for (
            dimension,
            score
        ) in window[
            "dimensions"
        ].items():

            print(
                f"  {dimension:20} : "
                f"{score}"
            )


    # ========================================================
    # SIGNALS
    # ========================================================

    print()

    print(
        "WELLNESS SIGNALS"
    )

    print(
        "-" * 70
    )


    signals = wellness[
        "signals"
    ]


    if not signals:

        print(
            "  No significant trend detected."
        )

    else:

        for signal in signals:

            print(
                f"  • "
                f"{signal['dimension']} "
                f"→ "
                f"{signal['direction']} "
                f"(strength: "
                f"{signal['strength']})"
            )


    # ========================================================
    # DATA QUALITY
    # ========================================================

    print()

    print(
        "DATA QUALITY"
    )

    print(
        "-" * 70
    )


    data_quality = result[
        "dataQuality"
    ]


    print(
        f"{'Records analyzed':35} : "
        f"{data_quality['recordCount']}"
    )


    print(
        f"{'Completeness':35} : "
        f"{data_quality['completeness']}%"
    )


    print(
        f"{'Recency':35} : "
        f"{data_quality['recency']}%"
    )


    print(
        f"{'Confidence':35} : "
        f"{data_quality['confidence']}%"
    )


    print(
        f"{'Quality level':35} : "
        f"{data_quality['level']}"
    )


    # ========================================================
    # METHOD
    # ========================================================

    print()

    print(
        "SCORING METHOD"
    )

    print(
        "-" * 70
    )


    method = wellness[
        "method"
    ]


    print(
        f"{'ML baseline weight':35} : "
        f"{method['mlBaselineWeight']}"
    )


    print(
        f"{'Longitudinal weight':35} : "
        f"{method['longitudinalWeight']}"
    )


    print()

    print(
        "Window weights:"
    )


    for (
        window,
        weight
    ) in method[
        "windowWeights"
    ].items():

        print(
            f"  {window:20} : "
            f"{weight}"
        )


    print()

    print(
        "Dimension weights:"
    )


    for (
        dimension,
        weight
    ) in method[
        "dimensionWeights"
    ].items():

        print(
            f"  {dimension:20} : "
            f"{weight}"
        )

    # ========================================================
    # EXPLAINABILITY
    # ========================================================

    explanation = result[
        "explanation"
    ]   


    print()

    print(
        "EXPLAINABILITY"
        )

    print(
        "-" * 70
    )


    print(
        "Trend:"
    )

    print(
        f"  {explanation['trendExplanation']}"
    )


    print()

    print(
        "Strongest Factors:"
    )


    for factor in (
        explanation[
            "positiveFactors"
        ]
    ):

        print(
            f"  ✓ "
            f"{factor['label']}: "
            f"{factor['score']} "
            f"({factor['level']})"
        )


    print()

    print(
        "Attention Factors:"
    )


    if explanation[
        "attentionFactors"
    ]:

        for factor in (
            explanation[
                "attentionFactors"
            ]
        ):

            print(
                f"  ! "
                f"{factor['label']}: "
                f"{factor['score']} "
                f"({factor['level']})"
            )

    else:

        print(
            "  No major attention factors."
        )


    print()

    print(
        "Summary:"
    )

    print(
        f"  {explanation['positiveSummary']}"
    )

    print(
        f"  {explanation['attentionSummary']}"
    )

    # ========================================================
    # RECOMMENDATIONS
    # ========================================================

    recommendation_result = result[
        "recommendations"
    ]


    print()

    print(
        "PERSONALIZED RECOMMENDATIONS"
    )

    print(
        "-" * 70
    )


    print(
        "Overall:"
    )

    print(
        f"  {recommendation_result['overallMessage']}"
    )


    print()

    print(
        "Trend:"
    )

    print(
        f"  {recommendation_result['trendMessage']}"
    )


    print()

    for recommendation in (
        recommendation_result[
            "recommendations"
        ]
    ):

        print(
            f"[{recommendation['priority'].upper()}] "
            f"{recommendation['label']}"
        )

        print(
            f"  Reason : "
            f"{recommendation['reason']}"
        )

        print(
            f"  Action : "
            f"{recommendation['action']}"
        )

        print(
            f"  Goal   : "
            f"{recommendation['goal']}"
        )

        print()

    # ========================================================
    # SYSTEM INFORMATION
    # ========================================================

    print()

    print(
        "SYSTEM"
    )

    print(
        "-" * 70
    )


    print(
        f"{'Model version':35} : "
        f"{result['modelVersion']}"
    )


    print(
        f"{'Blood pressure used':35} : "
        f"{result['bloodPressureUsed']}"
    )


    print(
        f"{'Records analyzed':35} : "
        f"{result['recordsAnalyzed']}"
    )


    print()

    print(
        "=" * 70
    )

    print(
        "ANALYSIS COMPLETE"
    )

    print(
        "=" * 70
    )


# ============================================================
# ENTRY POINT
# ============================================================

if __name__ == "__main__":

    main()
from prediction.inference import analyze_user


# ============================================================
# MAIN
# ============================================================

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
        # Heart rate stable
        # ----------------------------------------------------

        heart_rate = 73


        # ----------------------------------------------------
        # Weight stable
        # ----------------------------------------------------

        weight = (
            70.5
            -
            (
                0.5 * progress
            )
        )


        # ----------------------------------------------------
        # BMI stable
        # ----------------------------------------------------

        bmi = (
            22.95
            -
            (
                0.15 * progress
            )
        )


        # ----------------------------------------------------
        # Add health record
        # ----------------------------------------------------

        health_records.append({

            "date":
                f"2026-08-{day:02d}",

            "steps":
                steps,

            "activeHours":
                round(
                    active_hours,
                    2,
                ),

            "activeZoneMinutes":
                active_zone,

            "heartRate":
                heart_rate,

            "restingHeartRate":
                round(
                    resting_hr,
                    2,
                ),

            "sleep":
                round(
                    sleep,
                    2,
                ),

            "weight":
                round(
                    weight,
                    2,
                ),

            "bmi":
                round(
                    bmi,
                    2,
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

        health_records,
    )


    # ========================================================
    # HEADER
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
        result[
            "scores"
        ].items()
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
    # PERSONAL WELLNESS
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
    # LONGITUDINAL WINDOWS
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


    for window_name in (
        "7d",
        "14d",
        "30d",
    ):

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
            score,
        ) in window[
            "dimensions"
        ].items():

            print(
                f"  {dimension:20} : "
                f"{score}"
            )


    # ========================================================
    # WELLNESS SIGNALS
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
    # SCORING METHOD
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
        weight,
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
        weight,
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
        f"  "
        f"{explanation['trendExplanation']}"
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
        f"  "
        f"{explanation['positiveSummary']}"
    )

    print(
        f"  "
        f"{explanation['attentionSummary']}"
    )


    # ========================================================
    # PERSONALIZED RECOMMENDATIONS
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
        f"  "
        f"{recommendation_result['overallMessage']}"
    )


    print()

    print(
        "Trend:"
    )

    print(
        f"  "
        f"{recommendation_result['trendMessage']}"
    )


    # --------------------------------------------------------
    # Main opportunity
    # --------------------------------------------------------

    print()

    print(
        "MAIN OPPORTUNITY"
    )

    print(
        "-" * 70
    )


    main_opportunity = (
        recommendation_result[
            "mainOpportunity"
        ]
    )


    if main_opportunity:

        print(
            f"Area     : "
            f"{main_opportunity['label']}"
        )

        print(
            f"Score    : "
            f"{main_opportunity['score']}"
        )

        print(
            f"Priority : "
            f"{main_opportunity['priority'].upper()}"
        )

        print(
            f"Reason   : "
            f"{main_opportunity['reason']}"
        )

        print(
            f"Action   : "
            f"{main_opportunity['action']}"
        )

        print(
            f"Goal     : "
            f"{main_opportunity['goal']}"
        )

    else:

        print(
            "No major opportunity identified."
        )


    # --------------------------------------------------------
    # Other actionable recommendations
    # --------------------------------------------------------

    print()

    print(
        "OTHER RECOMMENDATIONS"
    )

    print(
        "-" * 70
    )


    recommendations = (
        recommendation_result[
            "recommendations"
        ]
    )


    main_dimension = (

        main_opportunity[
            "dimension"
        ]

        if main_opportunity

        else None
    )


    found_other = False


    for recommendation in recommendations:

        if (
            recommendation[
                "dimension"
            ]
            ==
            main_dimension
        ):

            continue


        found_other = True


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


    if not found_other:

        print(
            "No additional actionable recommendations."
        )


    # --------------------------------------------------------
    # Maintenance
    # --------------------------------------------------------

    print(
        "MAINTAIN"
    )

    print(
        "-" * 70
    )

    maintenance = (
        recommendation_result.get(
            "maintenance",
            []
        )
    )

    if maintenance:

        for item in maintenance:

            label = item.get(
                "label",
                "Unknown"
            )

            score = item.get(
                "score"
            )

            if score is not None:

                print(
                    f"  ✓ "
                    f"{label}: "
                    f"{score}"
                )

            else:

                print(
                    f"  ✓ "
                    f"{label}"
                )

    else:

        print(
            "  No specific maintenance areas."
        )
    # ========================================================
    # WELLBEING FORECAST
    # ========================================================

    forecast = result[
        "forecast"
    ]


    print()

    print(
        "WELLBEING FORECAST"
    )

    print(
        "-" * 70
    )


    print(
        f"{'Current Score':35} : "
        f"{forecast['current']}"
    )

    print(
        f"{'7-Day Forecast':35} : "
        f"{forecast['forecast7d']}"
    )

    print(
        f"{'14-Day Forecast':35} : "
        f"{forecast['forecast14d']}"
    )

    print(
        f"{'30-Day Forecast':35} : "
        f"{forecast['forecast30d']}"
    )

    print(
        f"{'Trajectory':35} : "
        f"{forecast['trajectory']}"
    )

    print(
        f"{'Confidence':35} : "
        f"{forecast['confidence']}%"
    )


    # ========================================================
    # AI INTERPRETATION
    # ========================================================

    ai_result = result[
        "aiInterpretation"
    ]


    print()

    print(
        "AI WELLBEING INTERPRETATION"
    )

    print(
        "-" * 70
    )


    # --------------------------------------------------------
    # Summary
    # --------------------------------------------------------

    print()

    print(
        "SUMMARY"
    )

    print(
        ai_result[
            "summary"
        ]
    )


    # --------------------------------------------------------
    # Strengths
    # --------------------------------------------------------

    print()

    print(
        "STRENGTHS"
    )


    for strength in (
        ai_result[
            "strengths"
        ]
    ):

        print(
            f"  ✓ {strength}"
        )


    # --------------------------------------------------------
    # Opportunities
    # --------------------------------------------------------

    print()

    print(
        "OPPORTUNITIES"
    )


    for opportunity in (
        ai_result[
            "opportunities"
        ]
    ):

        print(
            f"  • {opportunity}"
        )


    # --------------------------------------------------------
    # Actions
    # --------------------------------------------------------

    print()

    print(
        "ACTIONS"
    )


    for action in (
        ai_result[
            "actions"
        ]
    ):

        print(
            f"  → {action}"
        )


    # --------------------------------------------------------
    # Forecast interpretation
    # --------------------------------------------------------

    print()

    print(
        "FORECAST INTERPRETATION"
    )

    print(
        "-" * 70
    )


    print(
        ai_result.get(
            "forecast",
            "No forecast interpretation available.",
        )
    )


    # --------------------------------------------------------
    # Narrative
    # --------------------------------------------------------

    print()

    print(
        "NARRATIVE"
    )

    print(
        "-" * 70
    )


    print(
        ai_result[
            "narrative"
        ]
    )


    # ========================================================
    # AI METADATA
    # ========================================================

    print()

    print(
        "AI METADATA"
    )


    print(
        f"{'Provider':35} : "
        f"{ai_result['provider']}"
    )

    print(
        f"{'Grounded':35} : "
        f"{ai_result['grounded']}"
    )

    print(
        f"{'Medical Diagnosis':35} : "
        f"{ai_result['medicalDiagnosis']}"
    )


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


    # ========================================================
    # COMPLETE
    # ========================================================

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
import json
from pathlib import Path


# ============================================================
# PATHS
# ============================================================

OUTPUT_DIR = Path(
    "outputs"
)


V1_FILE = (
    OUTPUT_DIR
    /
    "v1_results.json"
)


V2_FILE = (
    OUTPUT_DIR
    /
    "v2_results.json"
)


COMPARISON_FILE = (
    OUTPUT_DIR
    /
    "model_comparison.json"
)


# ============================================================
# LOAD RESULTS
# ============================================================

def load_results(path):

    if not path.exists():

        return None


    with open(

        path,

        "r",

        encoding="utf-8"

    ) as file:

        return json.load(
            file
        )


# ============================================================
# NORMALIZE RESULT FORMAT
# ============================================================

def normalize_results(data):

    # --------------------------------------------------------
    # V1 FORMAT
    #
    # {
    #     "model_version": "V1",
    #     "model_epoch": 2,
    #     "test_accuracy": ...,
    #     "class_metrics": {
    #         "class_0": {... "f1_score": ...},
    #         "class_1": {... "f1_score": ...}
    #     }
    # }
    # --------------------------------------------------------

    if "class_metrics" in data:

        return {

            "model_version":

                data.get(
                    "model_version",
                    "V1"
                ),


            "best_epoch":

                data.get(
                    "model_epoch"
                ),


            "test_accuracy":

                data.get(
                    "test_accuracy"
                ),


            "test_samples":

                data.get(
                    "test_samples"
                ),


            "class_0": {

                "class_name":

                    data[
                        "class_metrics"
                    ][
                        "class_0"
                    ].get(
                        "class_name",
                        "Class 0"
                    ),


                "precision":

                    data[
                        "class_metrics"
                    ][
                        "class_0"
                    ].get(
                        "precision"
                    ),


                "recall":

                    data[
                        "class_metrics"
                    ][
                        "class_0"
                    ].get(
                        "recall"
                    ),


                "f1":

                    data[
                        "class_metrics"
                    ][
                        "class_0"
                    ].get(
                        "f1_score"
                    ),


                "support":

                    data[
                        "class_metrics"
                    ][
                        "class_0"
                    ].get(
                        "support"
                    )

            },


            "class_1": {

                "class_name":

                    data[
                        "class_metrics"
                    ][
                        "class_1"
                    ].get(
                        "class_name",
                        "Class 1"
                    ),


                "precision":

                    data[
                        "class_metrics"
                    ][
                        "class_1"
                    ].get(
                        "precision"
                    ),


                "recall":

                    data[
                        "class_metrics"
                    ][
                        "class_1"
                    ].get(
                        "recall"
                    ),


                "f1":

                    data[
                        "class_metrics"
                    ][
                        "class_1"
                    ].get(
                        "f1_score"
                    ),


                "support":

                    data[
                        "class_metrics"
                    ][
                        "class_1"
                    ].get(
                        "support"
                    )

            },


            "confusion_matrix":

                data.get(
                    "confusion_matrix"
                )

        }


    # --------------------------------------------------------
    # V2 FORMAT
    #
    # {
    #     "model_version": "V2",
    #     "best_epoch": 9,
    #     "test_accuracy": ...,
    #     "class_0": {... "f1": ...},
    #     "class_1": {... "f1": ...}
    # }
    # --------------------------------------------------------

    return {

        "model_version":

            data.get(
                "model_version",
                "Unknown"
            ),


        "best_epoch":

            data.get(
                "best_epoch",
                data.get(
                    "model_epoch"
                )
            ),


        "test_accuracy":

            data.get(
                "test_accuracy"
            ),


        "test_samples":

            data.get(
                "test_samples"
            ),


        "class_0": {

            "class_name":

                data.get(
                    "class_0",
                    {}
                ).get(
                    "class_name",
                    "Class 0"
                ),


            "precision":

                data.get(
                    "class_0",
                    {}
                ).get(
                    "precision"
                ),


            "recall":

                data.get(
                    "class_0",
                    {}
                ).get(
                    "recall"
                ),


            "f1":

                data.get(
                    "class_0",
                    {}
                ).get(
                    "f1",
                    data.get(
                        "class_0",
                        {}
                    ).get(
                        "f1_score"
                    )
                ),


            "support":

                data.get(
                    "class_0",
                    {}
                ).get(
                    "support"
                )

        },


        "class_1": {

            "class_name":

                data.get(
                    "class_1",
                    {}
                ).get(
                    "class_name",
                    "Class 1"
                ),


            "precision":

                data.get(
                    "class_1",
                    {}
                ).get(
                    "precision"
                ),


            "recall":

                data.get(
                    "class_1",
                    {}
                ).get(
                    "recall"
                ),


            "f1":

                data.get(
                    "class_1",
                    {}
                ).get(
                    "f1",
                    data.get(
                        "class_1",
                        {}
                    ).get(
                        "f1_score"
                    )
                ),


            "support":

                data.get(
                    "class_1",
                    {}
                ).get(
                    "support"
                )

        },


        "confusion_matrix":

            data.get(
                "confusion_matrix"
            )

    }


# ============================================================
# FORMAT PERCENTAGE
# ============================================================

def percentage(value):

    if value is None:

        return "N/A"


    return (
        f"{value * 100:.2f}%"
    )


# ============================================================
# MAIN
# ============================================================

def main():

    print("=" * 70)

    print(
        "FACIAL STRESS MODEL COMPARISON"
    )

    print("=" * 70)


    # --------------------------------------------------------
    # LOAD RAW RESULTS
    # --------------------------------------------------------

    v1_raw = load_results(
        V1_FILE
    )


    v2_raw = load_results(
        V2_FILE
    )


    if v1_raw is None:

        print(
            "\nV1 results not found:"
        )

        print(
            V1_FILE
        )


    if v2_raw is None:

        print(
            "\nV2 results not found:"
        )

        print(
            V2_FILE
        )


    if v1_raw is None or v2_raw is None:

        print(
            "\nBoth V1 and V2 "
            "evaluation files are required."
        )

        return


    # --------------------------------------------------------
    # NORMALIZE RESULTS
    # --------------------------------------------------------

    v1 = normalize_results(
        v1_raw
    )


    v2 = normalize_results(
        v2_raw
    )


    # --------------------------------------------------------
    # MODEL PERFORMANCE
    # --------------------------------------------------------

    print(
        "\nMODEL PERFORMANCE"
    )


    print(
        "-" * 70
    )


    print(

        f"{'Metric':<25}"

        f"{'V1':<20}"

        f"{'V2':<20}"

    )


    print(
        "-" * 70
    )


    metrics = [

        (

            "Test Accuracy",

            v1[
                "test_accuracy"
            ],

            v2[
                "test_accuracy"
            ]

        ),

        (

            "Class 0 F1",

            v1[
                "class_0"
            ][
                "f1"
            ],

            v2[
                "class_0"
            ][
                "f1"
            ]

        ),

        (

            "Class 1 F1",

            v1[
                "class_1"
            ][
                "f1"
            ],

            v2[
                "class_1"
            ][
                "f1"
            ]

        )

    ]


    for name, v1_value, v2_value in metrics:

        print(

            f"{name:<25}"

            f"{percentage(v1_value):<20}"

            f"{percentage(v2_value):<20}"

        )


    # --------------------------------------------------------
    # ADDITIONAL INFORMATION
    # --------------------------------------------------------

    print(
        "-" * 70
    )


    print(

        f"{'Best Epoch':<25}"

        f"{str(v1['best_epoch']):<20}"

        f"{str(v2['best_epoch']):<20}"

    )


    print(

        f"{'Test Samples':<25}"

        f"{str(v1['test_samples']):<20}"

        f"{str(v2['test_samples']):<20}"

    )


    # --------------------------------------------------------
    # DECIDE WINNER
    # --------------------------------------------------------

    v1_accuracy = (
        v1[
            "test_accuracy"
        ]
    )


    v2_accuracy = (
        v2[
            "test_accuracy"
        ]
    )


    if v2_accuracy > v1_accuracy:

        winner = "V2"


    elif v1_accuracy > v2_accuracy:

        winner = "V1"


    else:

        winner = "DRAW"


    # --------------------------------------------------------
    # ACCURACY CHANGE
    # --------------------------------------------------------

    improvement = (

        v2_accuracy

        -

        v1_accuracy

    ) * 100


    # --------------------------------------------------------
    # DISPLAY WINNER
    # --------------------------------------------------------

    print(
        "\n" + "=" * 70
    )


    print(
        f"BEST MODEL: {winner}"
    )


    print(
        "=" * 70
    )


    print(

        f"\nV2 Accuracy Change: "

        f"{improvement:+.2f}%"

    )


    if winner == "V1":

        print(

            "\nRecommendation: "

            "V1 should be selected as the current "

            "production model."

        )


    elif winner == "V2":

        print(

            "\nRecommendation: "

            "V2 should be selected as the current "

            "production model."

        )


    else:

        print(

            "\nRecommendation: "

            "Both models have equal test accuracy."

        )


    # --------------------------------------------------------
    # SAVE COMPARISON
    # --------------------------------------------------------

    comparison = {

        "v1": {

            "model_version":

                v1[
                    "model_version"
                ],

            "best_epoch":

                v1[
                    "best_epoch"
                ],

            "test_accuracy":

                float(
                    v1_accuracy
                ),

            "test_samples":

                int(
                    v1[
                        "test_samples"
                    ]
                ),

            "class_0":

                v1[
                    "class_0"
                ],

            "class_1":

                v1[
                    "class_1"
                ]

        },


        "v2": {

            "model_version":

                v2[
                    "model_version"
                ],

            "best_epoch":

                v2[
                    "best_epoch"
                ],

            "test_accuracy":

                float(
                    v2_accuracy
                ),

            "test_samples":

                int(
                    v2[
                        "test_samples"
                    ]
                ),

            "class_0":

                v2[
                    "class_0"
                ],

            "class_1":

                v2[
                    "class_1"
                ]

        },


        "accuracy_change":

            float(
                v2_accuracy
                -
                v1_accuracy
            ),


        "accuracy_change_percent":

            float(
                improvement
            ),


        "winner":

            winner

    }


    OUTPUT_DIR.mkdir(
        parents=True,
        exist_ok=True
    )


    with open(

        COMPARISON_FILE,

        "w",

        encoding="utf-8"

    ) as file:

        json.dump(

            comparison,

            file,

            indent=4

        )


    print(
        "\nComparison saved:"
    )


    print(
        COMPARISON_FILE
    )


    print(
        "\n" + "=" * 70
    )


    print(
        "COMPARISON COMPLETE"
    )


    print(
        "=" * 70
    )


# ============================================================
# RUN
# ============================================================

if __name__ == "__main__":

    main()
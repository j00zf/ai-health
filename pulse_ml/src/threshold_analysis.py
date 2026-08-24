import joblib
import numpy as np
import pandas as pd

from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
)


MODEL_PATH = (
    "../models/advanced/xgboost.pkl"
)

VALIDATION_FILE = (
    "../models/advanced/validation.csv"
)


FEATURES = [
    "age_years",
    "sex",
    "height",
    "weight",
    "bmi",
    "smoke",
    "alco",
    "active",
    "ap_hi",
    "ap_lo",
    "cholesterol",
]


def main():

    print("=" * 80)
    print(
        "PULSE AI ADVANCED — "
        "VALIDATION THRESHOLD ANALYSIS"
    )
    print("=" * 80)

    # =========================================================
    # LOAD MODEL
    # =========================================================

    model = joblib.load(
        MODEL_PATH
    )

    # =========================================================
    # LOAD VALIDATION DATA
    # =========================================================

    df = pd.read_csv(
        VALIDATION_FILE
    )

    X = df[
        FEATURES
    ]

    y = df[
        "cardio"
    ]

    # =========================================================
    # PREDICT PROBABILITIES
    # =========================================================

    probabilities = (
        model.predict_proba(X)[:, 1]
    )

    results = []

    # =========================================================
    # TEST THRESHOLDS
    # =========================================================

    for threshold in np.arange(
        0.20,
        0.81,
        0.01,
    ):

        predictions = (
            probabilities >= threshold
        ).astype(int)

        results.append(
            {
                "threshold":
                    round(
                        float(threshold),
                        2,
                    ),

                "accuracy":
                    accuracy_score(
                        y,
                        predictions,
                    ),

                "precision":
                    precision_score(
                        y,
                        predictions,
                        zero_division=0,
                    ),

                "recall":
                    recall_score(
                        y,
                        predictions,
                        zero_division=0,
                    ),

                "f1":
                    f1_score(
                        y,
                        predictions,
                        zero_division=0,
                    ),
            }
        )

    results = pd.DataFrame(
        results
    )

    # =========================================================
    # BEST F1
    # =========================================================

    best_f1 = results.loc[
        results["f1"].idxmax()
    ]

    # =========================================================
    # BEST BALANCED THRESHOLD
    #
    # We don't blindly use maximum F1 for production.
    # This is reported separately.
    # =========================================================

    balanced = results[
        (
            results["recall"] >= 0.75
        )
        &
        (
            results["precision"] >= 0.65
        )
    ]

    if len(balanced) > 0:

        balanced = balanced.copy()

        balanced["distance"] = (
            abs(
                balanced["precision"]
                -
                balanced["recall"]
            )
        )

        best_balanced = balanced.loc[
            balanced["distance"].idxmin()
        ]

    else:

        best_balanced = None

    # =========================================================
    # PRINT RESULTS
    # =========================================================

    print("\n")
    print(
        results.to_string(
            index=False
        )
    )

    print("\n")
    print("=" * 80)
    print("BEST F1 THRESHOLD")
    print("=" * 80)

    print(
        f"Threshold : "
        f"{best_f1['threshold']:.2f}"
    )

    print(
        f"Accuracy  : "
        f"{best_f1['accuracy']:.4f}"
    )

    print(
        f"Precision : "
        f"{best_f1['precision']:.4f}"
    )

    print(
        f"Recall    : "
        f"{best_f1['recall']:.4f}"
    )

    print(
        f"F1        : "
        f"{best_f1['f1']:.4f}"
    )

    if best_balanced is not None:

        print("\n")
        print(
            "=" * 80
        )

        print(
            "BALANCED CANDIDATE"
        )

        print(
            "=" * 80
        )

        print(
            f"Threshold : "
            f"{best_balanced['threshold']:.2f}"
        )

        print(
            f"Accuracy  : "
            f"{best_balanced['accuracy']:.4f}"
        )

        print(
            f"Precision : "
            f"{best_balanced['precision']:.4f}"
        )

        print(
            f"Recall    : "
            f"{best_balanced['recall']:.4f}"
        )

        print(
            f"F1        : "
            f"{best_balanced['f1']:.4f}"
        )

    # =========================================================
    # SAVE RESULTS
    # =========================================================

    results.to_csv(
        "../reports/"
        "advanced_validation_thresholds.csv",
        index=False,
    )

    # =========================================================
    # SAVE CANDIDATE THRESHOLD
    # =========================================================

    threshold_config = pd.DataFrame(
        [
            {
                "model":
                    "pulse_ai_advanced_xgboost_v1",

                "selection_method":
                    "validation_max_f1",

                "threshold":
                    float(
                        best_f1["threshold"]
                    ),
            }
        ]
    )

    threshold_config.to_json(
        "../reports/"
        "advanced_threshold_config.json",
        orient="records",
        indent=2,
    )

    print("\n")
    print(
        "Validation results saved."
    )


if __name__ == "__main__":
    main()
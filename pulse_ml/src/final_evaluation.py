import json
import joblib
import pandas as pd

from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    roc_auc_score,
    average_precision_score,
    confusion_matrix,
)


MODEL_PATH = (
    "../models/advanced/xgboost.pkl"
)

TEST_FILE = (
    "../models/advanced/test.csv"
)

THRESHOLD_FILE = (
    "../reports/"
    "advanced_threshold_config.json"
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
        "FINAL TEST EVALUATION"
    )
    print("=" * 80)

    # =========================================================
    # LOAD MODEL
    # =========================================================

    model = joblib.load(
        MODEL_PATH
    )

    # =========================================================
    # LOAD TEST DATA
    # =========================================================

    df = pd.read_csv(
        TEST_FILE
    )

    X = df[
        FEATURES
    ]

    y = df[
        "cardio"
    ]

    # =========================================================
    # LOAD THRESHOLD
    # =========================================================

    with open(
        THRESHOLD_FILE,
        "r",
    ) as file:

        config = json.load(
            file
        )

    threshold = float(
        config[0]["threshold"]
    )

    print(
        f"\nSelected threshold: "
        f"{threshold:.2f}"
    )

    # =========================================================
    # PROBABILITIES
    # =========================================================

    probabilities = (
        model.predict_proba(X)[:, 1]
    )

    # =========================================================
    # APPLY VALIDATION-SELECTED THRESHOLD
    # =========================================================

    predictions = (
        probabilities >= threshold
    ).astype(int)

    # =========================================================
    # METRICS
    # =========================================================

    accuracy = accuracy_score(
        y,
        predictions,
    )

    precision = precision_score(
        y,
        predictions,
        zero_division=0,
    )

    recall = recall_score(
        y,
        predictions,
        zero_division=0,
    )

    f1 = f1_score(
        y,
        predictions,
        zero_division=0,
    )

    roc_auc = roc_auc_score(
        y,
        probabilities,
    )

    average_precision = (
        average_precision_score(
            y,
            probabilities,
        )
    )

    # =========================================================
    # CONFUSION MATRIX
    # =========================================================

    tn, fp, fn, tp = (
        confusion_matrix(
            y,
            predictions,
        ).ravel()
    )

    # =========================================================
    # RESULTS
    # =========================================================

    print("\n")
    print("=" * 80)
    print("FINAL TEST RESULTS")
    print("=" * 80)

    print(
        f"Accuracy          : "
        f"{accuracy:.4f}"
    )

    print(
        f"Precision         : "
        f"{precision:.4f}"
    )

    print(
        f"Recall            : "
        f"{recall:.4f}"
    )

    print(
        f"F1                : "
        f"{f1:.4f}"
    )

    print(
        f"ROC-AUC           : "
        f"{roc_auc:.4f}"
    )

    print(
        f"Average Precision : "
        f"{average_precision:.4f}"
    )

    print("\n")
    print(
        "Confusion Matrix:"
    )

    print(
        confusion_matrix(
            y,
            predictions,
        )
    )

    print("\n")
    print(
        f"True Negative  : {tn}"
    )

    print(
        f"False Positive : {fp}"
    )

    print(
        f"False Negative : {fn}"
    )

    print(
        f"True Positive  : {tp}"
    )

    # =========================================================
    # SAVE FINAL RESULTS
    # =========================================================

    results = {
        "model":
            "pulse_ai_advanced_xgboost_v1",

        "threshold":
            threshold,

        "accuracy":
            accuracy,

        "precision":
            precision,

        "recall":
            recall,

        "f1":
            f1,

        "roc_auc":
            roc_auc,

        "average_precision":
            average_precision,

        "true_negative":
            int(tn),

        "false_positive":
            int(fp),

        "false_negative":
            int(fn),

        "true_positive":
            int(tp),
    }

    with open(
        "../reports/"
        "advanced_final_results.json",
        "w",
    ) as file:

        json.dump(
            results,
            file,
            indent=2,
        )

    print("\n")
    print(
        "Final results saved to:"
    )

    print(
        "../reports/"
        "advanced_final_results.json"
    )


if __name__ == "__main__":
    main()
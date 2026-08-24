import os
import joblib
import pandas as pd
import numpy as np

import matplotlib.pyplot as plt

from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    roc_auc_score,
    confusion_matrix,
    roc_curve,
    precision_recall_curve,
    average_precision_score,
)


BASE_DIR = ".."

MODELS = {
    "lite": {
        "features": [
            "age_years",
            "sex",
            "height",
            "weight",
            "bmi",
            "smoke",
            "alco",
            "active",
        ],
        "test": "../models/lite/test.csv",
    },

    "advanced": {
        "features": [
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
        ],
        "test": "../models/advanced/test.csv",
    },
}


MODEL_NAMES = [
    "logistic",
    "random_forest",
    "xgboost",
]


OUTPUT_DIR = "../reports"

os.makedirs(
    OUTPUT_DIR,
    exist_ok=True,
)


def evaluate_model(
    model,
    X,
    y,
):

    predictions = model.predict(X)

    probabilities = model.predict_proba(X)[:, 1]

    tn, fp, fn, tp = confusion_matrix(
        y,
        predictions,
    ).ravel()

    metrics = {
        "accuracy": accuracy_score(
            y,
            predictions,
        ),

        "precision": precision_score(
            y,
            predictions,
            zero_division=0,
        ),

        "recall": recall_score(
            y,
            predictions,
            zero_division=0,
        ),

        "f1": f1_score(
            y,
            predictions,
            zero_division=0,
        ),

        "roc_auc": roc_auc_score(
            y,
            probabilities,
        ),

        "average_precision": average_precision_score(
            y,
            probabilities,
        ),

        "TN": tn,
        "FP": fp,
        "FN": fn,
        "TP": tp,
    }

    return metrics, predictions, probabilities


def save_confusion_matrix(
    y,
    predictions,
    model_name,
    model_type,
):

    matrix = confusion_matrix(
        y,
        predictions,
    )

    fig, ax = plt.subplots(
        figsize=(6, 5)
    )

    image = ax.imshow(
        matrix,
        interpolation="nearest",
    )

    ax.set_title(
        f"Pulse AI {model_type.title()} - "
        f"{model_name.title()} Confusion Matrix"
    )

    ax.set_xlabel(
        "Predicted Class"
    )

    ax.set_ylabel(
        "Actual Class"
    )

    ax.set_xticks(
        [0, 1]
    )

    ax.set_yticks(
        [0, 1]
    )

    ax.set_xticklabels(
        [
            "No Cardiovascular Event",
            "Cardiovascular Event",
        ],
        rotation=20,
        ha="right",
    )

    ax.set_yticklabels(
        [
            "No Cardiovascular Event",
            "Cardiovascular Event",
        ]
    )

    threshold = matrix.max() / 2

    for i in range(2):
        for j in range(2):

            ax.text(
                j,
                i,
                str(matrix[i, j]),
                ha="center",
                va="center",
                color=(
                    "white"
                    if matrix[i, j] > threshold
                    else "black"
                ),
                fontsize=14,
                fontweight="bold",
            )

    fig.colorbar(
        image,
        ax=ax,
    )

    plt.tight_layout()

    filename = (
        f"{OUTPUT_DIR}/"
        f"{model_type}_{model_name}_"
        f"confusion_matrix.png"
    )

    plt.savefig(
        filename,
        dpi=200,
        bbox_inches="tight",
    )

    plt.close()

    return filename


def save_normalized_confusion_matrix(
    y,
    predictions,
    model_name,
    model_type,
):

    matrix = confusion_matrix(
        y,
        predictions,
        normalize="true",
    )

    fig, ax = plt.subplots(
        figsize=(6, 5)
    )

    image = ax.imshow(
        matrix,
        interpolation="nearest",
    )

    ax.set_title(
        f"Normalized Confusion Matrix\n"
        f"{model_type.title()} - "
        f"{model_name.title()}"
    )

    ax.set_xlabel(
        "Predicted Class"
    )

    ax.set_ylabel(
        "Actual Class"
    )

    ax.set_xticks(
        [0, 1]
    )

    ax.set_yticks(
        [0, 1]
    )

    ax.set_xticklabels(
        ["Negative", "Positive"]
    )

    ax.set_yticklabels(
        ["Negative", "Positive"]
    )

    for i in range(2):
        for j in range(2):

            ax.text(
                j,
                i,
                f"{matrix[i, j]:.2%}",
                ha="center",
                va="center",
                color="white",
                fontsize=13,
                fontweight="bold",
            )

    fig.colorbar(
        image,
        ax=ax,
    )

    plt.tight_layout()

    filename = (
        f"{OUTPUT_DIR}/"
        f"{model_type}_{model_name}_"
        f"normalized_confusion_matrix.png"
    )

    plt.savefig(
        filename,
        dpi=200,
        bbox_inches="tight",
    )

    plt.close()

    return filename


def main():

    all_results = []

    print("=" * 80)
    print("PULSE AI MODEL EVALUATION")
    print("=" * 80)

    for model_type, configuration in MODELS.items():

        print("\n")
        print("=" * 80)
        print(
            f"PULSE AI {model_type.upper()}"
        )
        print("=" * 80)

        df = pd.read_csv(
            configuration["test"]
        )

        features = configuration[
            "features"
        ]

        X = df[features]

        y = df["cardio"]

        for model_name in MODEL_NAMES:

            model_path = (
                f"../models/"
                f"{model_type}/"
                f"{model_name}.pkl"
            )

            model = joblib.load(
                model_path
            )

            metrics, predictions, probabilities = (
                evaluate_model(
                    model,
                    X,
                    y,
                )
            )

            row = {
                "model_type":
                    model_type,

                "model":
                    model_name,

                **metrics,
            }

            all_results.append(
                row
            )

            print(
                f"\n{model_name.upper()}"
            )

            print(
                "-" * 50
            )

            print(
                f"Accuracy          : "
                f"{metrics['accuracy']:.4f}"
            )

            print(
                f"Precision         : "
                f"{metrics['precision']:.4f}"
            )

            print(
                f"Recall            : "
                f"{metrics['recall']:.4f}"
            )

            print(
                f"F1                : "
                f"{metrics['f1']:.4f}"
            )

            print(
                f"ROC-AUC           : "
                f"{metrics['roc_auc']:.4f}"
            )

            print(
                f"Average Precision : "
                f"{metrics['average_precision']:.4f}"
            )

            print(
                "\nConfusion Matrix:"
            )

            print(
                confusion_matrix(
                    y,
                    predictions,
                )
            )

            print(
                "\nTN:",
                metrics["TN"]
            )

            print(
                "FP:",
                metrics["FP"]
            )

            print(
                "FN:",
                metrics["FN"]
            )

            print(
                "TP:",
                metrics["TP"]
            )

            save_confusion_matrix(
                y,
                predictions,
                model_name,
                model_type,
            )

            save_normalized_confusion_matrix(
                y,
                predictions,
                model_name,
                model_type,
            )

    # =========================================================
    # SAVE RESULTS
    # =========================================================

    results = pd.DataFrame(
        all_results
    )

    results = results.sort_values(
        [
            "model_type",
            "roc_auc",
        ],
        ascending=[
            True,
            False,
        ],
    )

    results.to_csv(
        f"{OUTPUT_DIR}/model_comparison.csv",
        index=False,
    )

    print("\n")
    print("=" * 80)
    print("MODEL COMPARISON")
    print("=" * 80)

    print(
        results[
            [
                "model_type",
                "model",
                "accuracy",
                "precision",
                "recall",
                "f1",
                "roc_auc",
                "average_precision",
            ]
        ].to_string(
            index=False
        )
    )

    # =========================================================
    # BEST MODELS
    # =========================================================

    print("\n")
    print("=" * 80)
    print("BEST MODELS")
    print("=" * 80)

    for model_type in [
        "lite",
        "advanced",
    ]:

        subset = results[
            results["model_type"]
            == model_type
        ]

        best = subset.iloc[0]

        print(
            f"\n{model_type.upper()}"
        )

        print(
            f"Best model: "
            f"{best['model']}"
        )

        print(
            f"ROC-AUC: "
            f"{best['roc_auc']:.4f}"
        )

        print(
            f"F1: "
            f"{best['f1']:.4f}"
        )

    print("\nReports saved to:")
    print(
        os.path.abspath(
            OUTPUT_DIR
        )
    )


if __name__ == "__main__":
    main()
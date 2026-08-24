import os
import joblib
import pandas as pd
import matplotlib.pyplot as plt

from sklearn.metrics import (
    roc_curve,
    roc_auc_score,
    precision_recall_curve,
    average_precision_score,
)


OUTPUT_DIR = "../reports/curves"

os.makedirs(
    OUTPUT_DIR,
    exist_ok=True,
)


CONFIG = {
    "lite": {
        "test": "../models/lite/test.csv",

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
    },

    "advanced": {
        "test": "../models/advanced/test.csv",

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
    },
}


MODELS = [
    "logistic",
    "random_forest",
    "xgboost",
]


def main():

    # =========================================================
    # ROC CURVES
    # =========================================================

    for model_type, config in CONFIG.items():

        df = pd.read_csv(
            config["test"]
        )

        X = df[
            config["features"]
        ]

        y = df["cardio"]

        plt.figure(
            figsize=(8, 6)
        )

        for model_name in MODELS:

            model = joblib.load(
                f"../models/"
                f"{model_type}/"
                f"{model_name}.pkl"
            )

            probability = (
                model.predict_proba(X)[:, 1]
            )

            fpr, tpr, _ = roc_curve(
                y,
                probability,
            )

            auc = roc_auc_score(
                y,
                probability,
            )

            plt.plot(
                fpr,
                tpr,
                label=(
                    f"{model_name.upper()} "
                    f"(AUC={auc:.4f})"
                ),
            )

        plt.plot(
            [0, 1],
            [0, 1],
            linestyle="--",
            label="Random baseline",
        )

        plt.xlabel(
            "False Positive Rate"
        )

        plt.ylabel(
            "True Positive Rate"
        )

        plt.title(
            f"Pulse AI {model_type.title()} "
            f"ROC Curves"
        )

        plt.legend()

        plt.grid(
            alpha=0.2
        )

        plt.tight_layout()

        plt.savefig(
            f"{OUTPUT_DIR}/"
            f"{model_type}_roc_curves.png",
            dpi=200,
        )

        plt.close()

    # =========================================================
    # PRECISION-RECALL CURVES
    # =========================================================

    for model_type, config in CONFIG.items():

        df = pd.read_csv(
            config["test"]
        )

        X = df[
            config["features"]
        ]

        y = df["cardio"]

        plt.figure(
            figsize=(8, 6)
        )

        for model_name in MODELS:

            model = joblib.load(
                f"../models/"
                f"{model_type}/"
                f"{model_name}.pkl"
            )

            probability = (
                model.predict_proba(X)[:, 1]
            )

            precision, recall, _ = (
                precision_recall_curve(
                    y,
                    probability,
                )
            )

            ap = average_precision_score(
                y,
                probability,
            )

            plt.plot(
                recall,
                precision,
                label=(
                    f"{model_name.upper()} "
                    f"(AP={ap:.4f})"
                ),
            )

        plt.xlabel(
            "Recall"
        )

        plt.ylabel(
            "Precision"
        )

        plt.title(
            f"Pulse AI {model_type.title()} "
            f"Precision-Recall Curves"
        )

        plt.legend()

        plt.grid(
            alpha=0.2
        )

        plt.tight_layout()

        plt.savefig(
            f"{OUTPUT_DIR}/"
            f"{model_type}_pr_curves.png",
            dpi=200,
        )

        plt.close()

    print(
        "ROC and Precision-Recall curves saved."
    )


if __name__ == "__main__":
    main()
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

TEST_FILE = (
    "../models/advanced/test.csv"
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

    model = joblib.load(
        MODEL_PATH
    )

    df = pd.read_csv(
        TEST_FILE
    )

    X = df[FEATURES]

    y = df["cardio"]

    probabilities = (
        model.predict_proba(X)[:, 1]
    )

    results = []

    for threshold in np.arange(
        0.20,
        0.81,
        0.05,
    ):

        predictions = (
            probabilities >= threshold
        ).astype(int)

        results.append(
            {
                "threshold":
                    round(
                        threshold,
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

    print("=" * 80)
    print(
        "PULSE AI ADVANCED — "
        "THRESHOLD ANALYSIS"
    )
    print("=" * 80)

    print(
        results.to_string(
            index=False
        )
    )

    results.to_csv(
        "../reports/"
        "advanced_thresholds.csv",
        index=False,
    )


if __name__ == "__main__":
    main()
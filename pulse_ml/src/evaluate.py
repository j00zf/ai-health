import joblib
import pandas as pd

from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    roc_auc_score,
    confusion_matrix,
    classification_report,
)


TEST_FILE = (
    "../data/processed/"
    "test_v1.csv"
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
]


MODELS = {
    "Logistic Regression":
        "../models/logistic_v1.pkl",

    "Random Forest":
        "../models/random_forest_v1.pkl",

    "XGBoost":
        "../models/xgboost_v1.pkl",
}


def evaluate(
    name,
    model,
    X,
    y,
):

    prediction = model.predict(
        X
    )

    probability = model.predict_proba(
        X
    )[:, 1]

    print(
        f"\n{'=' * 70}"
    )

    print(name)

    print(
        f"{'=' * 70}"
    )

    print(
        f"Accuracy : "
        f"{accuracy_score(y, prediction):.4f}"
    )

    print(
        f"Precision: "
        f"{precision_score(y, prediction):.4f}"
    )

    print(
        f"Recall   : "
        f"{recall_score(y, prediction):.4f}"
    )

    print(
        f"F1       : "
        f"{f1_score(y, prediction):.4f}"
    )

    print(
        f"ROC-AUC  : "
        f"{roc_auc_score(y, probability):.4f}"
    )

    print(
        "\nConfusion matrix:"
    )

    print(
        confusion_matrix(
            y,
            prediction,
        )
    )


def main():

    df = pd.read_csv(
        TEST_FILE
    )

    X = df[
        FEATURES
    ]

    y = df[
        "target"
    ]

    for name, path in MODELS.items():

        model = joblib.load(
            path
        )

        evaluate(
            name,
            model,
            X,
            y,
        )


if __name__ == "__main__":
    main()
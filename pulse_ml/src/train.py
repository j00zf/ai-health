from pathlib import Path

import joblib
import pandas as pd

from sklearn.model_selection import (
    train_test_split,
)

from sklearn.impute import SimpleImputer

from sklearn.pipeline import Pipeline

from sklearn.preprocessing import StandardScaler

from sklearn.linear_model import LogisticRegression

from sklearn.ensemble import (
    RandomForestClassifier,
)

from xgboost import XGBClassifier


DATASET = (
    "../data/processed/"
    "cardio_v1_clean.csv"
)

MODEL_DIR = "../models"


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


def main():

    Path(
        MODEL_DIR
    ).mkdir(
        parents=True,
        exist_ok=True,
    )

    df = pd.read_csv(
        DATASET
    )

    X = df[
        FEATURES
    ]

    y = df[
        "cardio"
    ]

    # =========================================================
    # TRAIN / TEST
    # =========================================================

    X_train, X_test, y_train, y_test = (
        train_test_split(
            X,
            y,
            test_size=0.20,
            random_state=42,
            stratify=y,
        )
    )

    print(
        f"Training samples: "
        f"{len(X_train)}"
    )

    print(
        f"Testing samples: "
        f"{len(X_test)}"
    )

    # =========================================================
    # LOGISTIC REGRESSION
    # =========================================================

    logistic = Pipeline(
        [
            (
                "imputer",
                SimpleImputer(
                    strategy="median"
                ),
            ),

            (
                "scaler",
                StandardScaler(),
            ),

            (
                "model",
                LogisticRegression(
                    max_iter=2000
                ),
            ),
        ]
    )

    logistic.fit(
        X_train,
        y_train,
    )

    joblib.dump(
        logistic,
        f"{MODEL_DIR}/logistic_v1.pkl",
    )

    # =========================================================
    # RANDOM FOREST
    # =========================================================

    random_forest = Pipeline(
        [
            (
                "imputer",
                SimpleImputer(
                    strategy="median"
                ),
            ),

            (
                "model",
                RandomForestClassifier(
                    n_estimators=400,
                    max_depth=10,
                    min_samples_leaf=5,
                    class_weight="balanced",
                    random_state=42,
                    n_jobs=-1,
                ),
            ),
        ]
    )

    random_forest.fit(
        X_train,
        y_train,
    )

    joblib.dump(
        random_forest,
        f"{MODEL_DIR}/random_forest_v1.pkl",
    )

    # =========================================================
    # XGBOOST
    # =========================================================

    xgb = XGBClassifier(
        n_estimators=400,
        max_depth=5,
        learning_rate=0.04,
        subsample=0.8,
        colsample_bytree=0.8,
        objective="binary:logistic",
        eval_metric="logloss",
        random_state=42,
    )

    xgb.fit(
        X_train,
        y_train,
    )

    joblib.dump(
        xgb,
        f"{MODEL_DIR}/xgboost_v1.pkl",
    )

    # =========================================================
    # SAVE TEST SET
    # =========================================================

    test = X_test.copy()

    test["target"] = y_test

    test.to_csv(
        "../data/processed/"
        "test_v1.csv",
        index=False,
    )

    print(
        "\nModels saved."
    )


if __name__ == "__main__":
    main()
import os

import joblib
import pandas as pd

from sklearn.model_selection import train_test_split

from sklearn.pipeline import Pipeline

from sklearn.impute import SimpleImputer

from sklearn.preprocessing import StandardScaler

from sklearn.linear_model import LogisticRegression

from sklearn.ensemble import RandomForestClassifier

from xgboost import XGBClassifier


DATASET = (
    "../data/processed/"
    "cardio_clean_common.csv"
)

MODEL_DIR = "../models/advanced"

os.makedirs(
    MODEL_DIR,
    exist_ok=True,
)


FEATURES = [
    # ---------------------------------------------------------
    # Profile
    # ---------------------------------------------------------

    "age_years",
    "sex",
    "height",
    "weight",
    "bmi",

    # ---------------------------------------------------------
    # Lifestyle
    # ---------------------------------------------------------

    "smoke",
    "alco",
    "active",

    # ---------------------------------------------------------
    # Clinical
    # ---------------------------------------------------------

    "ap_hi",
    "ap_lo",
    "cholesterol",
]


def main():

    df = pd.read_csv(
        DATASET
    )

    X = df[
        FEATURES
    ]

    y = df[
        "cardio"
    ]

    X_train, X_test, y_train, y_test = (
        train_test_split(
            X,
            y,
            test_size=0.20,
            random_state=42,
            stratify=y,
        )
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
                    max_iter=2000,
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
        f"{MODEL_DIR}/logistic.pkl",
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
        f"{MODEL_DIR}/random_forest.pkl",
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
        f"{MODEL_DIR}/xgboost.pkl",
    )

    test = X_test.copy()

    test["cardio"] = y_test

    test.to_csv(
        f"{MODEL_DIR}/test.csv",
        index=False,
    )

    print("=" * 70)
    print("PULSE AI ADVANCED TRAINING COMPLETE")
    print("=" * 70)

    print(
        f"Training samples: {len(X_train)}"
    )

    print(
        f"Testing samples: {len(X_test)}"
    )


if __name__ == "__main__":
    main()
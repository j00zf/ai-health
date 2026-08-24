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


# ============================================================================
# CONFIGURATION
# ============================================================================

DATASET = (
    "../data/processed/"
    "cardio_clean_common.csv"
)

MODEL_DIR = "../models/advanced"

os.makedirs(
    MODEL_DIR,
    exist_ok=True,
)


# ============================================================================
# FEATURES
# ============================================================================
#
# Pulse AI Advanced v1
#
# Profile:
#   age
#   sex
#   height
#   weight
#   BMI
#
# Lifestyle:
#   smoking
#   alcohol
#   activity
#
# Clinical:
#   systolic BP
#   diastolic BP
#   cholesterol
#
# Intentionally excluded:
#   glucose
#   HbA1c
#   LDL
#   HDL
#   triglycerides
# ============================================================================

FEATURES = [
    # Profile
    "age_years",
    "sex",
    "height",
    "weight",
    "bmi",

    # Lifestyle
    "smoke",
    "alco",
    "active",

    # Clinical
    "ap_hi",
    "ap_lo",
    "cholesterol",
]


TARGET = "cardio"


# ============================================================================
# MAIN
# ============================================================================

def main():

    print("=" * 70)
    print("PULSE AI ADVANCED — TRAINING")
    print("=" * 70)

    # ------------------------------------------------------------------------
    # LOAD DATA
    # ------------------------------------------------------------------------

    df = pd.read_csv(
        DATASET
    )

    print(
        f"\nTotal records: {len(df)}"
    )

    # ------------------------------------------------------------------------
    # FEATURES + TARGET
    # ------------------------------------------------------------------------

    X = df[
        FEATURES
    ]

    y = df[
        TARGET
    ]

    print(
        f"Features: {len(FEATURES)}"
    )

    print(
        "\nFeatures used:"
    )

    for feature in FEATURES:
        print(
            f"  - {feature}"
        )

    # =========================================================================
    # DATA SPLITTING
    # =========================================================================
    #
    # 70% Training
    # 10% Validation
    # 20% Final Test
    #
    # The final test set will NOT be used for threshold selection.
    # =========================================================================

    # ------------------------------------------------------------------------
    # FIRST SPLIT
    #
    # 80% development
    # 20% final test
    # ------------------------------------------------------------------------

    X_dev, X_test, y_dev, y_test = train_test_split(
        X,
        y,
        test_size=0.20,
        random_state=42,
        stratify=y,
    )

    # ------------------------------------------------------------------------
    # SECOND SPLIT
    #
    # Development:
    #
    # 80% of 80% = 64% overall training
    # 20% of 80% = 16% overall validation
    #
    # Therefore:
    #
    # Training   = 64%
    # Validation = 16%
    # Test       = 20%
    # ------------------------------------------------------------------------

    X_train, X_val, y_train, y_val = train_test_split(
        X_dev,
        y_dev,
        test_size=0.20,
        random_state=42,
        stratify=y_dev,
    )

    print("\n" + "=" * 70)
    print("DATA SPLIT")
    print("=" * 70)

    print(
        f"Training samples   : {len(X_train)}"
    )

    print(
        f"Validation samples : {len(X_val)}"
    )

    print(
        f"Testing samples    : {len(X_test)}"
    )

    # =========================================================================
    # LOGISTIC REGRESSION
    # =========================================================================

    print("\nTraining Logistic Regression...")

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

    print(
        "Logistic Regression saved."
    )

    # =========================================================================
    # RANDOM FOREST
    # =========================================================================

    print(
        "\nTraining Random Forest..."
    )

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

    print(
        "Random Forest saved."
    )

    # =========================================================================
    # XGBOOST
    # =========================================================================

    print(
        "\nTraining XGBoost..."
    )

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

    print(
        "XGBoost saved."
    )

    # =========================================================================
    # SAVE TRAINING / VALIDATION / TEST DATA
    # =========================================================================

    train_data = X_train.copy()

    train_data[TARGET] = y_train

    train_data.to_csv(
        f"{MODEL_DIR}/train.csv",
        index=False,
    )

    validation_data = X_val.copy()

    validation_data[TARGET] = y_val

    validation_data.to_csv(
        f"{MODEL_DIR}/validation.csv",
        index=False,
    )

    test_data = X_test.copy()

    test_data[TARGET] = y_test

    test_data.to_csv(
        f"{MODEL_DIR}/test.csv",
        index=False,
    )

    # =========================================================================
    # SUMMARY
    # =========================================================================

    print("\n" + "=" * 70)
    print(
        "PULSE AI ADVANCED TRAINING COMPLETE"
    )
    print("=" * 70)

    print(
        f"Training samples   : {len(X_train)}"
    )

    print(
        f"Validation samples : {len(X_val)}"
    )

    print(
        f"Testing samples    : {len(X_test)}"
    )

    print(
        "\nModels saved to:"
    )

    print(
        os.path.abspath(
            MODEL_DIR
        )
    )

    print(
        "\nSaved datasets:"
    )

    print(
        "  - train.csv"
    )

    print(
        "  - validation.csv"
    )

    print(
        "  - test.csv"
    )


# ============================================================================
# ENTRY POINT
# ============================================================================

if __name__ == "__main__":
    main()
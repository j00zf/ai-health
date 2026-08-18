from __future__ import annotations

import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd

from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    accuracy_score,
    average_precision_score,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import (
    StratifiedKFold,
    cross_validate,
    train_test_split,
)
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from xgboost import XGBClassifier

from .config import (
    CATEGORICAL_FEATURES,
    CV_FOLDS,
    DATA_PATH,
    FEATURES,
    MODEL_DIR,
    NUMERIC_FEATURES,
    RANDOM_STATE,
    REPORT_DIR,
    TARGET,
    TEST_SIZE,
)
from .data import clean_basic, load_dataset


# ============================================================
# PREPROCESSING
# ============================================================

def make_logistic_preprocessor():

    numeric_pipeline = Pipeline(
        steps=[
            (
                "imputer",
                SimpleImputer(
                    strategy="median",
                    add_indicator=True,
                ),
            ),
            (
                "scaler",
                StandardScaler(),
            ),
        ]
    )

    categorical_pipeline = Pipeline(
        steps=[
            (
                "imputer",
                SimpleImputer(
                    strategy="most_frequent",
                    add_indicator=True,
                ),
            ),
            (
                "onehot",
                OneHotEncoder(
                    handle_unknown="ignore",
                    sparse_output=False,
                ),
            ),
        ]
    )

    return ColumnTransformer(
        transformers=[
            (
                "numeric",
                numeric_pipeline,
                NUMERIC_FEATURES,
            ),
            (
                "categorical",
                categorical_pipeline,
                CATEGORICAL_FEATURES,
            ),
        ],
        remainder="drop",
    )


def make_tree_preprocessor():

    return ColumnTransformer(
        transformers=[
            (
                "all_features",
                SimpleImputer(
                    strategy="median",
                    add_indicator=True,
                ),
                FEATURES,
            ),
        ],
        remainder="drop",
    )


# ============================================================
# MODELS
# ============================================================

def make_logistic_pipeline():

    model = LogisticRegression(
        max_iter=3000,
        class_weight="balanced",
        random_state=RANDOM_STATE,
    )

    return Pipeline(
        steps=[
            (
                "preprocessor",
                make_logistic_preprocessor(),
            ),
            (
                "model",
                model,
            ),
        ]
    )


def make_random_forest_pipeline():

    model = RandomForestClassifier(
        n_estimators=600,
        min_samples_leaf=5,
        class_weight="balanced",
        random_state=RANDOM_STATE,
        n_jobs=-1,
    )

    return Pipeline(
        steps=[
            (
                "preprocessor",
                make_tree_preprocessor(),
            ),
            (
                "model",
                model,
            ),
        ]
    )


def make_xgboost_pipeline():

    model = XGBClassifier(
        n_estimators=400,
        max_depth=3,
        learning_rate=0.03,
        subsample=0.8,
        colsample_bytree=0.8,
        min_child_weight=5,
        reg_lambda=2.0,
        objective="binary:logistic",
        eval_metric="logloss",
        random_state=RANDOM_STATE,
        n_jobs=-1,
    )

    return Pipeline(
        steps=[
            (
                "preprocessor",
                make_tree_preprocessor(),
            ),
            (
                "model",
                model,
            ),
        ]
    )


def build_models():

    return {
        "logistic_regression_v2":
            make_logistic_pipeline(),

        "random_forest_v2":
            make_random_forest_pipeline(),

        "xgboost_v1":
            make_xgboost_pipeline(),
    }


# ============================================================
# CROSS VALIDATION
# ============================================================

def run_cross_validation(
    models,
    X_train,
    y_train,
):

    cv = StratifiedKFold(
        n_splits=CV_FOLDS,
        shuffle=True,
        random_state=RANDOM_STATE,
    )

    scoring = {
        "roc_auc": "roc_auc",
        "pr_auc": "average_precision",
        "accuracy": "accuracy",
        "precision": "precision",
        "recall": "recall",
        "f1": "f1",
    }

    results = []

    for name, model in models.items():

        print()
        print("=" * 70)
        print(f"Evaluating: {name}")
        print("=" * 70)

        scores = cross_validate(
            model,
            X_train,
            y_train,
            cv=cv,
            scoring=scoring,
            n_jobs=-1,
            return_train_score=False,
            error_score="raise",
        )

        result = {
            "model": name,

            "roc_auc_mean":
                scores["test_roc_auc"].mean(),

            "roc_auc_std":
                scores["test_roc_auc"].std(),

            "pr_auc_mean":
                scores["test_pr_auc"].mean(),

            "pr_auc_std":
                scores["test_pr_auc"].std(),

            "accuracy_mean":
                scores["test_accuracy"].mean(),

            "precision_mean":
                scores["test_precision"].mean(),

            "recall_mean":
                scores["test_recall"].mean(),

            "f1_mean":
                scores["test_f1"].mean(),
        }

        results.append(result)

        print(
            f"ROC-AUC : "
            f"{result['roc_auc_mean']:.4f}"
        )

        print(
            f"PR-AUC  : "
            f"{result['pr_auc_mean']:.4f}"
        )

        print(
            f"Recall  : "
            f"{result['recall_mean']:.4f}"
        )

        print(
            f"F1      : "
            f"{result['f1_mean']:.4f}"
        )

    return (
        pd.DataFrame(results)
        .sort_values(
            "roc_auc_mean",
            ascending=False,
        )
        .reset_index(drop=True)
    )


# ============================================================
# TEST EVALUATION
# ============================================================

def evaluate_test(
    model,
    X_test,
    y_test,
):

    predictions = model.predict(
        X_test
    )

    probabilities = (
        model
        .predict_proba(X_test)[:, 1]
    )

    metrics = {
        "roc_auc": float(
            roc_auc_score(
                y_test,
                probabilities,
            )
        ),

        "pr_auc": float(
            average_precision_score(
                y_test,
                probabilities,
            )
        ),

        "accuracy": float(
            accuracy_score(
                y_test,
                predictions,
            )
        ),

        "precision": float(
            precision_score(
                y_test,
                predictions,
                zero_division=0,
            )
        ),

        "recall": float(
            recall_score(
                y_test,
                predictions,
                zero_division=0,
            )
        ),

        "f1": float(
            f1_score(
                y_test,
                predictions,
                zero_division=0,
            )
        ),

        "confusion_matrix":
            confusion_matrix(
                y_test,
                predictions,
            ).tolist(),
    }

    return metrics


# ============================================================
# MAIN TRAINING
# ============================================================

def main():

    MODEL_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    REPORT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    print("=" * 70)
    print("HEART RISK MODEL V2")
    print("=" * 70)

    print()
    print("Loading dataset:")
    print(DATA_PATH)

    # --------------------------------------------------------
    # Load and clean
    # --------------------------------------------------------

    df = clean_basic(
        load_dataset()
    )

    print()
    print(
        f"Rows after cleaning: "
        f"{len(df)}"
    )

    print(
        f"Positive target rate: "
        f"{df[TARGET].mean():.4f}"
    )

    # --------------------------------------------------------
    # Features and target
    # --------------------------------------------------------

    X = df[FEATURES].copy()

    y = df[TARGET].astype(int)

    # --------------------------------------------------------
    # Train/test split
    #
    # IMPORTANT:
    # The test set is NEVER used during model selection.
    # --------------------------------------------------------

    X_train, X_test, y_train, y_test = (
        train_test_split(
            X,
            y,
            test_size=TEST_SIZE,
            stratify=y,
            random_state=RANDOM_STATE,
        )
    )

    print()
    print(
        f"Training samples: "
        f"{len(X_train)}"
    )

    print(
        f"Test samples: "
        f"{len(X_test)}"
    )

    # --------------------------------------------------------
    # Build models
    # --------------------------------------------------------

    models = build_models()

    # --------------------------------------------------------
    # Cross validation
    # --------------------------------------------------------

    cv_results = run_cross_validation(
        models,
        X_train,
        y_train,
    )

    print()
    print("=" * 70)
    print("CROSS-VALIDATION RESULTS")
    print("=" * 70)

    print(
        cv_results.to_string(
            index=False,
            float_format=lambda x:
                f"{x:.4f}",
        )
    )

    # Save CV results

    cv_results.to_csv(
        REPORT_DIR /
        "v2_cv_results.csv",
        index=False,
    )

    # --------------------------------------------------------
    # Select model
    #
    # Temporary selection criterion:
    # highest CV ROC-AUC
    #
    # Later we will include calibration.
    # --------------------------------------------------------

    best_model_name = (
        cv_results
        .iloc[0]["model"]
    )

    best_model = models[
        best_model_name
    ]

    print()
    print(
        f"Selected model: "
        f"{best_model_name}"
    )

    # --------------------------------------------------------
    # Train selected model
    # --------------------------------------------------------

    print()
    print(
        "Training selected model..."
    )

    best_model.fit(
        X_train,
        y_train,
    )

    # --------------------------------------------------------
    # Final held-out test evaluation
    # --------------------------------------------------------

    test_metrics = evaluate_test(
        best_model,
        X_test,
        y_test,
    )

    print()
    print("=" * 70)
    print("HELD-OUT TEST RESULTS")
    print("=" * 70)

    print(
        f"ROC-AUC    : "
        f"{test_metrics['roc_auc']:.4f}"
    )

    print(
        f"PR-AUC     : "
        f"{test_metrics['pr_auc']:.4f}"
    )

    print(
        f"Accuracy   : "
        f"{test_metrics['accuracy']:.4f}"
    )

    print(
        f"Precision  : "
        f"{test_metrics['precision']:.4f}"
    )

    print(
        f"Recall     : "
        f"{test_metrics['recall']:.4f}"
    )

    print(
        f"F1         : "
        f"{test_metrics['f1']:.4f}"
    )

    print()
    print("Confusion Matrix:")

    print(
        np.array(
            test_metrics[
                "confusion_matrix"
            ]
        )
    )

    # --------------------------------------------------------
    # Save metrics
    # --------------------------------------------------------

    with open(
        REPORT_DIR /
        "v2_test_metrics.json",
        "w",
        encoding="utf-8",
    ) as file:

        json.dump(
            test_metrics,
            file,
            indent=2,
        )

    # --------------------------------------------------------
    # Save confusion matrix
    # --------------------------------------------------------

    confusion_df = pd.DataFrame(
        test_metrics[
            "confusion_matrix"
        ],
        index=[
            "actual_0",
            "actual_1",
        ],
        columns=[
            "predicted_0",
            "predicted_1",
        ],
    )

    confusion_df.to_csv(
        REPORT_DIR /
        "v2_confusion_matrix.csv"
    )

    # --------------------------------------------------------
    # Save model
    # --------------------------------------------------------

    model_path = (
        MODEL_DIR /
        "heart_risk_model_v2.joblib"
    )

    joblib.dump(
        best_model,
        model_path,
    )

    # --------------------------------------------------------
    # Save metadata
    # --------------------------------------------------------

    metadata = {
        "model_name":
            best_model_name,

        "model_version":
            "heart-risk-v2",

        "target":
            TARGET,

        "features":
            FEATURES,

        "test_size":
            TEST_SIZE,

        "cv_folds":
            CV_FOLDS,

        "random_state":
            RANDOM_STATE,

        "positive_target_rate":
            float(y.mean()),

        "test_metrics":
            test_metrics,
    }

    with open(
        MODEL_DIR /
        "heart_risk_model_v2_metadata.json",
        "w",
        encoding="utf-8",
    ) as file:

        json.dump(
            metadata,
            file,
            indent=2,
        )

    # --------------------------------------------------------
    # Done
    # --------------------------------------------------------

    print()
    print("=" * 70)
    print("MODEL SAVED")
    print("=" * 70)

    print(model_path)

    print()
    print("Reports:")

    print(
        REPORT_DIR /
        "v2_cv_results.csv"
    )

    print(
        REPORT_DIR /
        "v2_test_metrics.json"
    )

    print(
        REPORT_DIR /
        "v2_confusion_matrix.csv"
    )


if __name__ == "__main__":
    main()
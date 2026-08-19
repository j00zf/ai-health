from __future__ import annotations

import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd

from sklearn.calibration import CalibratedClassifierCV
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    average_precision_score,
    balanced_accuracy_score,
    brier_score_loss,
    confusion_matrix,
    f1_score,
    log_loss,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import (
    GridSearchCV,
    StratifiedKFold,
    cross_val_predict,
    train_test_split,
)
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import (
    OneHotEncoder,
    StandardScaler,
)

from .config import (
    FEATURES,
    NUMERIC_FEATURES,
    CATEGORICAL_FEATURES,
    TARGET,
    RANDOM_STATE,
    TEST_SIZE,
    CV_FOLDS,
    DATA_PATH,
    MODEL_DIR,
    REPORT_DIR,
)

from .data import (
    clean_basic,
    load_dataset,
)


# ============================================================
# V3 DIRECTORIES
# ============================================================

V3_REPORT_DIR = REPORT_DIR / "v3"

V3_PLOT_DIR = V3_REPORT_DIR / "plots"

V3_REPORT_DIR.mkdir(
    parents=True,
    exist_ok=True,
)

V3_PLOT_DIR.mkdir(
    parents=True,
    exist_ok=True,
)


# ============================================================
# IMPORTANT:
# Use a DIFFERENT random state for the final test split.
#
# The old test split was already inspected during V1/V2.
# ============================================================

FINAL_TEST_RANDOM_STATE = 20260818


# ============================================================
# PREPROCESSOR
# ============================================================

def make_preprocessor():

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


# ============================================================
# BASE MODEL
# ============================================================

def make_pipeline():

    model = LogisticRegression(
        max_iter=5000,
        random_state=RANDOM_STATE,
    )

    return Pipeline(
        steps=[
            (
                "preprocessor",
                make_preprocessor(),
            ),
            (
                "model",
                model,
            ),
        ]
    )


# ============================================================
# HYPERPARAMETER GRID
# ============================================================

def get_parameter_grid():

    return {
        "model__C": [
            0.001,
            0.003,
            0.01,
            0.03,
            0.1,
            0.3,
            1.0,
            3.0,
            10.0,
            30.0,
            100.0,
        ],

        "model__class_weight": [
            None,
            "balanced",
        ],

        "model__penalty": [
            "l2",
            "l1",
        ],

        "model__solver": [
            "liblinear",
        ],
    }


# ============================================================
# METRICS
# ============================================================

def probability_metrics(
    y_true,
    probabilities,
):

    return {
        "roc_auc": float(
            roc_auc_score(
                y_true,
                probabilities,
            )
        ),

        "pr_auc": float(
            average_precision_score(
                y_true,
                probabilities,
            )
        ),

        "brier_score": float(
            brier_score_loss(
                y_true,
                probabilities,
            )
        ),

        "log_loss": float(
            log_loss(
                y_true,
                probabilities,
            )
        ),
    }


# ============================================================
# THRESHOLD METRICS
# ============================================================

def threshold_metrics(
    y_true,
    probabilities,
    threshold,
):

    predictions = (
        probabilities >= threshold
    ).astype(int)

    tn, fp, fn, tp = confusion_matrix(
        y_true,
        predictions,
        labels=[0, 1],
    ).ravel()

    sensitivity = (
        tp / (tp + fn)
        if tp + fn > 0
        else 0.0
    )

    specificity = (
        tn / (tn + fp)
        if tn + fp > 0
        else 0.0
    )

    return {
        "threshold": threshold,

        "accuracy":
            accuracy_score(
                y_true,
                predictions,
            ),

        "balanced_accuracy":
            balanced_accuracy_score(
                y_true,
                predictions,
            ),

        "precision":
            precision_score(
                y_true,
                predictions,
                zero_division=0,
            ),

        "recall":
            recall_score(
                y_true,
                predictions,
                zero_division=0,
            ),

        "sensitivity":
            sensitivity,

        "specificity":
            specificity,

        "f1":
            f1_score(
                y_true,
                predictions,
                zero_division=0,
            ),

        "tn": int(tn),
        "fp": int(fp),
        "fn": int(fn),
        "tp": int(tp),
    }


# ============================================================
# MAIN
# ============================================================

def main():

    print("=" * 75)
    print("HEART RISK MODEL V3 - HYPERPARAMETER TUNING")
    print("=" * 75)

    # --------------------------------------------------------
    # LOAD
    # --------------------------------------------------------

    print()
    print("Loading:")
    print(DATA_PATH)

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

    X = df[FEATURES].copy()

    y = df[TARGET].astype(int)

    # --------------------------------------------------------
    # NEW FINAL TEST SPLIT
    #
    # This split is NEVER used during tuning.
    # --------------------------------------------------------

    X_dev, X_final_test, y_dev, y_final_test = (
        train_test_split(
            X,
            y,
            test_size=TEST_SIZE,
            stratify=y,
            random_state=FINAL_TEST_RANDOM_STATE,
        )
    )

    print()
    print("=" * 75)
    print("FINAL DATA SPLIT")
    print("=" * 75)

    print(
        f"Development samples : "
        f"{len(X_dev)}"
    )

    print(
        f"Final test samples  : "
        f"{len(X_final_test)}"
    )

    print()
    print(
        "IMPORTANT: final test set "
        "will remain untouched."
    )

    # ========================================================
    # HYPERPARAMETER TUNING
    # ========================================================

    print()
    print("=" * 75)
    print("HYPERPARAMETER SEARCH")
    print("=" * 75)

    pipeline = make_pipeline()

    parameter_grid = get_parameter_grid()

    cv = StratifiedKFold(
        n_splits=CV_FOLDS,
        shuffle=True,
        random_state=RANDOM_STATE,
    )

    search = GridSearchCV(
        estimator=pipeline,
        param_grid=parameter_grid,
        scoring="roc_auc",
        cv=cv,
        n_jobs=-1,
        refit=True,
        return_train_score=False,
        verbose=1,
    )

    search.fit(
        X_dev,
        y_dev,
    )

    print()
    print("=" * 75)
    print("BEST HYPERPARAMETERS")
    print("=" * 75)

    print(
        search.best_params_
    )

    print()
    print(
        f"Best CV ROC-AUC: "
        f"{search.best_score_:.6f}"
    )

    # --------------------------------------------------------
    # Save all grid results
    # --------------------------------------------------------

    grid_results = (
        pd.DataFrame(
            search.cv_results_
        )
        .sort_values(
            "rank_test_score"
        )
    )

    grid_results.to_csv(
        V3_REPORT_DIR /
        "hyperparameter_search.csv",
        index=False,
    )

    # --------------------------------------------------------
    # Save top configurations
    # --------------------------------------------------------

    top_results = grid_results[
        [
            "rank_test_score",
            "mean_test_score",
            "std_test_score",
            "param_model__C",
            "param_model__class_weight",
            "param_model__penalty",
            "param_model__solver",
        ]
    ].head(20)

    top_results.to_csv(
        V3_REPORT_DIR /
        "top_20_configurations.csv",
        index=False,
    )

    print()
    print("Top configurations:")

    print(
        top_results.to_string(
            index=False,
            float_format=lambda x:
                f"{x:.5f}",
        )
    )

    # ========================================================
    # BEST MODEL
    # ========================================================

    best_model = search.best_estimator_

    # ========================================================
    # OOF PREDICTIONS FOR BEST MODEL
    #
    # Used for calibration and threshold selection.
    # Final test remains untouched.
    # ========================================================

    print()
    print("=" * 75)
    print("GENERATING OUT-OF-FOLD PREDICTIONS")
    print("=" * 75)

    oof_cv = StratifiedKFold(
        n_splits=CV_FOLDS,
        shuffle=True,
        random_state=RANDOM_STATE,
    )

    oof_probabilities = (
        cross_val_predict(
            best_model,
            X_dev,
            y_dev,
            cv=oof_cv,
            method="predict_proba",
            n_jobs=-1,
        )[:, 1]
    )

    oof_metrics = probability_metrics(
        y_dev,
        oof_probabilities,
    )

    print()
    print(
        "Best model OOF probability metrics:"
    )

    for name, value in oof_metrics.items():

        print(
            f"{name:15s}: "
            f"{value:.6f}"
        )

    # ========================================================
    # CALIBRATION
    # ========================================================

    print()
    print("=" * 75)
    print("CALIBRATION COMPARISON")
    print("=" * 75)

    calibration_results = []

    calibrated_predictions = {}

    # --------------------------------------------------------
    # Uncalibrated
    # --------------------------------------------------------

    calibrated_predictions[
        "uncalibrated"
    ] = oof_probabilities

    # --------------------------------------------------------
    # Sigmoid
    # --------------------------------------------------------

    print(
        "Generating sigmoid calibration..."
    )

    sigmoid_model = CalibratedClassifierCV(
        estimator=make_pipeline(),
        method="sigmoid",
        cv=CV_FOLDS,
        ensemble=True,
    )

    sigmoid_oof = cross_val_predict(
        sigmoid_model,
        X_dev,
        y_dev,
        cv=oof_cv,
        method="predict_proba",
        n_jobs=-1,
    )[:, 1]

    calibrated_predictions[
        "sigmoid"
    ] = sigmoid_oof

    # --------------------------------------------------------
    # Isotonic
    # --------------------------------------------------------

    print(
        "Generating isotonic calibration..."
    )

    isotonic_model = CalibratedClassifierCV(
        estimator=make_pipeline(),
        method="isotonic",
        cv=CV_FOLDS,
        ensemble=True,
    )

    isotonic_oof = cross_val_predict(
        isotonic_model,
        X_dev,
        y_dev,
        cv=oof_cv,
        method="predict_proba",
        n_jobs=-1,
    )[:, 1]

    calibrated_predictions[
        "isotonic"
    ] = isotonic_oof

    # --------------------------------------------------------
    # Metrics
    # --------------------------------------------------------

    for method, probabilities in (
        calibrated_predictions.items()
    ):

        metrics = probability_metrics(
            y_dev,
            probabilities,
        )

        calibration_results.append(
            {
                "calibration": method,
                **metrics,
            }
        )

    calibration_df = pd.DataFrame(
        calibration_results
    )

    print()

    print(
        calibration_df.to_string(
            index=False,
            float_format=lambda x:
                f"{x:.6f}",
        )
    )

    calibration_df.to_csv(
        V3_REPORT_DIR /
        "calibration_comparison.csv",
        index=False,
    )

    # ========================================================
    # SELECT CALIBRATION
    #
    # Primary:
    # Brier score
    #
    # Secondary:
    # Log loss
    # ========================================================

    best_calibration_row = (
        calibration_df
        .sort_values(
            [
                "brier_score",
                "log_loss",
            ],
            ascending=True,
        )
        .iloc[0]
    )

    best_calibration = (
        best_calibration_row[
            "calibration"
        ]
    )

    print()
    print(
        f"Selected calibration: "
        f"{best_calibration}"
    )

    selected_probabilities = (
        calibrated_predictions[
            best_calibration
        ]
    )

    # ========================================================
    # THRESHOLD ANALYSIS
    # ========================================================

    print()
    print("=" * 75)
    print("THRESHOLD ANALYSIS")
    print("=" * 75)

    thresholds = [
        0.05,
        0.075,
        0.10,
        0.125,
        0.15,
        0.175,
        0.20,
        0.225,
        0.25,
        0.275,
        0.30,
        0.35,
        0.40,
        0.45,
        0.50,
    ]

    threshold_rows = []

    for threshold in thresholds:

        metrics = threshold_metrics(
            y_dev,
            selected_probabilities,
            threshold,
        )

        threshold_rows.append(
            metrics
        )

    threshold_df = pd.DataFrame(
        threshold_rows
    )

    threshold_df.to_csv(
        V3_REPORT_DIR /
        "threshold_analysis.csv",
        index=False,
    )

    print()

    print(
        threshold_df[
            [
                "threshold",
                "sensitivity",
                "specificity",
                "precision",
                "recall",
                "f1",
                "balanced_accuracy",
                "tp",
                "fp",
                "fn",
                "tn",
            ]
        ].to_string(
            index=False,
            float_format=lambda x:
                f"{x:.4f}",
        )
    )

    # --------------------------------------------------------
    # Candidate threshold:
    # highest F1
    #
    # This is a DEVELOPMENT selection only.
    # --------------------------------------------------------

    best_f1_row = (
        threshold_df
        .sort_values(
            [
                "f1",
                "balanced_accuracy",
            ],
            ascending=False,
        )
        .iloc[0]
    )

    best_threshold = float(
        best_f1_row[
            "threshold"
        ]
    )

    print()
    print(
        f"Candidate threshold by "
        f"F1: {best_threshold:.3f}"
    )

    # ========================================================
    # TRAIN FINAL CALIBRATED MODEL
    #
    # This uses ALL development data.
    # ========================================================

    print()
    print("=" * 75)
    print("TRAINING FINAL V3 DEVELOPMENT MODEL")
    print("=" * 75)

    final_base_model = search.best_estimator_

    final_base_model.fit(
        X_dev,
        y_dev,
    )

    if best_calibration == "sigmoid":

        final_calibrated_model = (
            CalibratedClassifierCV(
                estimator=final_base_model,
                method="sigmoid",
                cv=CV_FOLDS,
                ensemble=True,
            )
        )

    elif best_calibration == "isotonic":

        final_calibrated_model = (
            CalibratedClassifierCV(
                estimator=final_base_model,
                method="isotonic",
                cv=CV_FOLDS,
                ensemble=True,
            )
        )

    else:

        final_calibrated_model = (
            final_base_model
        )

    final_calibrated_model.fit(
        X_dev,
        y_dev,
    )

    # ========================================================
    # FINAL TEST
    #
    # THIS IS THE FIRST AND ONLY USE OF THE NEW FINAL TEST.
    # ========================================================

    print()
    print("=" * 75)
    print("FINAL TEST EVALUATION")
    print("=" * 75)

    final_test_probabilities = (
        final_calibrated_model
        .predict_proba(
            X_final_test
        )[:, 1]
    )

    final_test_probability_metrics = (
        probability_metrics(
            y_final_test,
            final_test_probabilities,
        )
    )

    print()
    print("Probability metrics:")

    for name, value in (
        final_test_probability_metrics.items()
    ):

        print(
            f"{name:15s}: "
            f"{value:.6f}"
        )

    # --------------------------------------------------------
    # Threshold-based test metrics
    #
    # Threshold was chosen using development OOF data.
    # --------------------------------------------------------

    final_test_threshold_metrics = (
        threshold_metrics(
            y_final_test,
            final_test_probabilities,
            best_threshold,
        )
    )

    print()
    print(
        f"Final threshold: "
        f"{best_threshold:.3f}"
    )

    print()

    for name, value in (
        final_test_threshold_metrics.items()
    ):

        if name not in [
            "threshold",
            "tn",
            "fp",
            "fn",
            "tp",
        ]:

            print(
                f"{name:20s}: "
                f"{value:.6f}"
            )

    print()

    print("Confusion matrix:")

    print(
        np.array(
            [
                [
                    final_test_threshold_metrics[
                        "tn"
                    ],
                    final_test_threshold_metrics[
                        "fp"
                    ],
                ],
                [
                    final_test_threshold_metrics[
                        "fn"
                    ],
                    final_test_threshold_metrics[
                        "tp"
                    ],
                ],
            ]
        )
    )

    # ========================================================
    # SAVE FINAL TEST RESULTS
    # ========================================================

    final_test_results = {
        "probability_metrics":
            final_test_probability_metrics,

        "threshold_metrics":
            final_test_threshold_metrics,

        "threshold":
            best_threshold,

        "calibration":
            best_calibration,

        "best_hyperparameters":
            search.best_params_,

        "final_test_random_state":
            FINAL_TEST_RANDOM_STATE,

        "note":
            (
                "This final test set was created "
                "with a new random state and was "
                "not used during hyperparameter "
                "tuning, calibration, or threshold "
                "selection."
            ),
    }

    with open(
        V3_REPORT_DIR /
        "final_test_results.json",
        "w",
        encoding="utf-8",
    ) as file:

        json.dump(
            final_test_results,
            file,
            indent=2,
        )

    # ========================================================
    # SAVE MODEL
    # ========================================================

    model_path = (
        MODEL_DIR /
        "heart_risk_model_v3_calibrated.joblib"
    )

    joblib.dump(
        final_calibrated_model,
        model_path,
    )

    # ========================================================
    # SAVE METADATA
    # ========================================================

    metadata = {
        "model_version":
            "heart-risk-v3",

        "model_type":
            "logistic_regression",

        "calibration":
            best_calibration,

        "threshold":
            best_threshold,

        "features":
            FEATURES,

        "numeric_features":
            NUMERIC_FEATURES,

        "categorical_features":
            CATEGORICAL_FEATURES,

        "target":
            TARGET,

        "positive_rate":
            float(y.mean()),

        "development_samples":
            len(X_dev),

        "final_test_samples":
            len(X_final_test),

        "hyperparameters":
            search.best_params_,

        "cv_roc_auc":
            float(search.best_score_),

        "calibration_metrics":
            calibration_df.to_dict(
                orient="records"
            ),

        "final_test_probability_metrics":
            final_test_probability_metrics,

        "final_test_threshold_metrics":
            final_test_threshold_metrics,

        "final_test_random_state":
            FINAL_TEST_RANDOM_STATE,
    }

    with open(
        MODEL_DIR /
        "heart_risk_model_v3_metadata.json",
        "w",
        encoding="utf-8",
    ) as file:

        json.dump(
            metadata,
            file,
            indent=2,
        )

    # ========================================================
    # SAVE OOF PREDICTIONS
    # ========================================================

    oof_df = pd.DataFrame(
        {
            "actual":
                y_dev.to_numpy(),

            "uncalibrated_probability":
                oof_probabilities,

            "sigmoid_probability":
                sigmoid_oof,

            "isotonic_probability":
                isotonic_oof,
        }
    )

    oof_df.to_csv(
        V3_REPORT_DIR /
        "oof_predictions.csv",
        index=False,
    )

    # ========================================================
    # COMPLETE
    # ========================================================

    print()
    print("=" * 75)
    print("V3 COMPLETE")
    print("=" * 75)

    print()
    print(
        "Model:"
    )

    print(
        model_path
    )

    print()
    print(
        "Reports:"
    )

    print(
        V3_REPORT_DIR
    )

    print()
    print(
        "Best hyperparameters:"
    )

    print(
        search.best_params_
    )

    print()
    print(
        f"Selected calibration: "
        f"{best_calibration}"
    )

    print(
        f"Candidate threshold: "
        f"{best_threshold:.3f}"
    )


if __name__ == "__main__":
    main()
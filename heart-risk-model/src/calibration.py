from __future__ import annotations

import json
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from sklearn.calibration import (
    CalibratedClassifierCV,
    calibration_curve,
)
from sklearn.metrics import (
    accuracy_score,
    average_precision_score,
    balanced_accuracy_score,
    brier_score_loss,
    f1_score,
    log_loss,
    precision_score,
    recall_score,
    roc_auc_score,
    confusion_matrix,
)
from sklearn.model_selection import (
    StratifiedKFold,
    cross_val_predict,
    train_test_split,
)

from .config import (
    CV_FOLDS,
    DATA_PATH,
    FEATURES,
    RANDOM_STATE,
    REPORT_DIR,
    TARGET,
    TEST_SIZE,
)

from .data import clean_basic, load_dataset

from .train_v2 import build_models


# ============================================================
# DIRECTORIES
# ============================================================

CALIBRATION_DIR = REPORT_DIR / "calibration"

PLOT_DIR = CALIBRATION_DIR / "plots"

CALIBRATION_DIR.mkdir(
    parents=True,
    exist_ok=True,
)

PLOT_DIR.mkdir(
    parents=True,
    exist_ok=True,
)


# ============================================================
# METRICS
# ============================================================

def calculate_probability_metrics(
    y_true,
    probabilities,
):
    """
    Evaluate probability predictions.

    These metrics evaluate the quality of the predicted
    probabilities, rather than converting them to 0/1.
    """

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
# CLASSIFICATION METRICS
# ============================================================

def calculate_threshold_metrics(
    y_true,
    probabilities,
    threshold,
):
    """
    Convert probabilities into binary predictions at a
    specified threshold and calculate classification metrics.
    """

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
        if (tp + fn) > 0
        else 0.0
    )

    specificity = (
        tn / (tn + fp)
        if (tn + fp) > 0
        else 0.0
    )

    npv = (
        tn / (tn + fn)
        if (tn + fn) > 0
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

        "npv":
            npv,

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
# OUT-OF-FOLD PREDICTIONS
# ============================================================

def generate_oof_predictions(
    model,
    X,
    y,
    cv,
):
    """
    Generate out-of-fold probabilities.

    Every prediction is made by a model that did not train
    on that particular record.
    """

    probabilities = cross_val_predict(
        model,
        X,
        y,
        cv=cv,
        method="predict_proba",
        n_jobs=-1,
    )[:, 1]

    return probabilities


# ============================================================
# CALIBRATED OUT-OF-FOLD PREDICTIONS
# ============================================================

def generate_calibrated_oof_predictions(
    model,
    X,
    y,
    outer_cv,
    method,
):
    """
    Generate properly out-of-fold predictions from a
    calibrated classifier.

    The outer fold creates the evaluation prediction.

    Inside each outer training fold, CalibratedClassifierCV
    performs its own internal CV to fit the calibration model.

    This avoids using the evaluation fold for calibration.
    """

    calibrated_model = CalibratedClassifierCV(
        estimator=model,
        method=method,
        cv=3,
        ensemble=True,
    )

    probabilities = cross_val_predict(
        calibrated_model,
        X,
        y,
        cv=outer_cv,
        method="predict_proba",
        n_jobs=-1,
    )[:, 1]

    return probabilities


# ============================================================
# CALIBRATION CURVE
# ============================================================

def plot_calibration_curves(
    y_true,
    prediction_dict,
):
    plt.figure(
        figsize=(8, 7)
    )

    # Perfect calibration line
    plt.plot(
        [0, 1],
        [0, 1],
        linestyle="--",
        label="Perfect calibration",
    )

    for name, probabilities in prediction_dict.items():

        fraction_positive, mean_predicted = (
            calibration_curve(
                y_true,
                probabilities,
                n_bins=10,
                strategy="quantile",
            )
        )

        plt.plot(
            mean_predicted,
            fraction_positive,
            marker="o",
            label=name,
        )

    plt.xlabel(
        "Mean predicted probability"
    )

    plt.ylabel(
        "Observed positive frequency"
    )

    plt.title(
        "Heart Risk Probability Calibration"
    )

    plt.legend()

    plt.grid(
        alpha=0.25
    )

    plt.tight_layout()

    plt.savefig(
        PLOT_DIR /
        "calibration_curves.png",
        dpi=180,
    )

    plt.close()


# ============================================================
# THRESHOLD CURVE
# ============================================================

def plot_threshold_metrics(
    threshold_df,
    model_name,
):
    plt.figure(
        figsize=(9, 6)
    )

    plt.plot(
        threshold_df["threshold"],
        threshold_df["sensitivity"],
        marker="o",
        label="Sensitivity",
    )

    plt.plot(
        threshold_df["threshold"],
        threshold_df["specificity"],
        marker="o",
        label="Specificity",
    )

    plt.plot(
        threshold_df["threshold"],
        threshold_df["precision"],
        marker="o",
        label="Precision",
    )

    plt.plot(
        threshold_df["threshold"],
        threshold_df["f1"],
        marker="o",
        label="F1",
    )

    plt.xlabel(
        "Classification threshold"
    )

    plt.ylabel(
        "Metric"
    )

    plt.title(
        f"Threshold Analysis - {model_name}"
    )

    plt.ylim(
        0,
        1.05
    )

    plt.grid(
        alpha=0.25
    )

    plt.legend()

    plt.tight_layout()

    filename = (
        model_name
        .lower()
        .replace(" ", "_")
        + "_threshold_analysis.png"
    )

    plt.savefig(
        PLOT_DIR / filename,
        dpi=180,
    )

    plt.close()


# ============================================================
# ANALYZE MODEL
# ============================================================

def analyze_model(
    model_name,
    model,
    X,
    y,
    outer_cv,
):
    print()
    print("=" * 70)
    print(
        f"MODEL: {model_name}"
    )
    print("=" * 70)

    # --------------------------------------------------------
    # Uncalibrated OOF predictions
    # --------------------------------------------------------

    print(
        "Generating uncalibrated "
        "out-of-fold predictions..."
    )

    uncalibrated = (
        generate_oof_predictions(
            model,
            X,
            y,
            outer_cv,
        )
    )

    # --------------------------------------------------------
    # Sigmoid calibration
    # --------------------------------------------------------

    print(
        "Generating sigmoid-calibrated "
        "out-of-fold predictions..."
    )

    sigmoid = (
        generate_calibrated_oof_predictions(
            model,
            X,
            y,
            outer_cv,
            method="sigmoid",
        )
    )

    # --------------------------------------------------------
    # Isotonic calibration
    # --------------------------------------------------------

    print(
        "Generating isotonic-calibrated "
        "out-of-fold predictions..."
    )

    isotonic = (
        generate_calibrated_oof_predictions(
            model,
            X,
            y,
            outer_cv,
            method="isotonic",
        )
    )

    predictions = {
        "uncalibrated": uncalibrated,
        "sigmoid": sigmoid,
        "isotonic": isotonic,
    }

    # --------------------------------------------------------
    # Probability metrics
    # --------------------------------------------------------

    probability_rows = []

    for method, probabilities in predictions.items():

        metrics = calculate_probability_metrics(
            y,
            probabilities,
        )

        probability_rows.append(
            {
                "model": model_name,
                "calibration": method,
                **metrics,
            }
        )

    probability_df = pd.DataFrame(
        probability_rows
    )

    print()
    print("Probability metrics:")

    print(
        probability_df.to_string(
            index=False,
            float_format=lambda x:
                f"{x:.4f}",
        )
    )

    # --------------------------------------------------------
    # Save probability metrics
    # --------------------------------------------------------

    probability_file = (
        CALIBRATION_DIR /
        f"{model_name}_probability_metrics.csv"
    )

    probability_df.to_csv(
        probability_file,
        index=False,
    )

    # --------------------------------------------------------
    # Threshold analysis
    # --------------------------------------------------------

    thresholds = [
        0.05,
        0.10,
        0.15,
        0.20,
        0.25,
        0.30,
        0.35,
        0.40,
        0.45,
        0.50,
        0.55,
        0.60,
        0.65,
        0.70,
        0.75,
        0.80,
    ]

    for method, probabilities in predictions.items():

        threshold_rows = []

        for threshold in thresholds:

            metrics = (
                calculate_threshold_metrics(
                    y,
                    probabilities,
                    threshold,
                )
            )

            threshold_rows.append(
                {
                    "model": model_name,
                    "calibration": method,
                    **metrics,
                }
            )

        threshold_df = pd.DataFrame(
            threshold_rows
        )

        filename = (
            f"{model_name}_"
            f"{method}_thresholds.csv"
        )

        threshold_df.to_csv(
            CALIBRATION_DIR / filename,
            index=False,
        )

        plot_threshold_metrics(
            threshold_df,
            f"{model_name} - {method}",
        )

    # --------------------------------------------------------
    # Save prediction data
    # --------------------------------------------------------

    prediction_df = pd.DataFrame(
        {
            "actual": y.to_numpy(),
            "uncalibrated_probability":
                uncalibrated,
            "sigmoid_probability":
                sigmoid,
            "isotonic_probability":
                isotonic,
        }
    )

    prediction_df.to_csv(
        CALIBRATION_DIR /
        f"{model_name}_oof_predictions.csv",
        index=False,
    )

    return predictions, probability_df


# ============================================================
# MAIN
# ============================================================

def main():

    print("=" * 70)
    print("HEART RISK MODEL - CALIBRATION & THRESHOLD ANALYSIS")
    print("=" * 70)

    # --------------------------------------------------------
    # Load dataset
    # --------------------------------------------------------

    df = clean_basic(
        load_dataset()
    )

    X = df[FEATURES].copy()

    y = df[TARGET].astype(int)

    # --------------------------------------------------------
    # IMPORTANT
    #
    # We create the same training split used previously.
    #
    # The test set is NOT used for this analysis.
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
        f"Training records: "
        f"{len(X_train)}"
    )

    print(
        f"Test records held out: "
        f"{len(X_test)}"
    )

    # --------------------------------------------------------
    # Outer CV
    # --------------------------------------------------------

    outer_cv = StratifiedKFold(
        n_splits=CV_FOLDS,
        shuffle=True,
        random_state=RANDOM_STATE,
    )

    # --------------------------------------------------------
    # Build models
    # --------------------------------------------------------

    models = build_models()

    all_probability_results = []

    all_predictions = {}

    # --------------------------------------------------------
    # Analyze each model
    # --------------------------------------------------------

    for model_name, model in models.items():

        predictions, probability_df = (
            analyze_model(
                model_name,
                model,
                X_train,
                y_train,
                outer_cv,
            )
        )

        all_probability_results.append(
            probability_df
        )

        all_predictions[
            model_name
        ] = predictions

    # --------------------------------------------------------
    # Combined probability results
    # --------------------------------------------------------

    combined = pd.concat(
        all_probability_results,
        ignore_index=True,
    )

    combined.to_csv(
        CALIBRATION_DIR /
        "all_probability_metrics.csv",
        index=False,
    )

    print()
    print("=" * 70)
    print("COMBINED PROBABILITY RESULTS")
    print("=" * 70)

    print(
        combined.to_string(
            index=False,
            float_format=lambda x:
                f"{x:.4f}",
        )
    )

    # --------------------------------------------------------
    # Calibration curves
    #
    # Create one plot per model.
    # --------------------------------------------------------

    for model_name, predictions in (
        all_predictions.items()
    ):

        plot_calibration_curves(
            y_train,
            predictions,
        )

        # Rename the generic plot
        generic_plot = (
            PLOT_DIR /
            "calibration_curves.png"
        )

        model_plot = (
            PLOT_DIR /
            (
                model_name
                .lower()
                .replace(" ", "_")
                + "_calibration_curves.png"
            )
        )

        if generic_plot.exists():

            generic_plot.replace(
                model_plot
            )

    # --------------------------------------------------------
    # Find best calibration according to
    # Brier score and log loss.
    #
    # LOWER is better.
    # --------------------------------------------------------

    best_brier = (
        combined
        .sort_values(
            "brier_score",
            ascending=True,
        )
        .iloc[0]
    )

    best_log_loss = (
        combined
        .sort_values(
            "log_loss",
            ascending=True,
        )
        .iloc[0]
    )

    print()
    print("=" * 70)
    print("BEST CALIBRATION RESULTS")
    print("=" * 70)

    print(
        "\nBest Brier score:"
    )

    print(
        f"Model       : "
        f"{best_brier['model']}"
    )

    print(
        f"Calibration : "
        f"{best_brier['calibration']}"
    )

    print(
        f"Brier score : "
        f"{best_brier['brier_score']:.6f}"
    )

    print(
        "\nBest log loss:"
    )

    print(
        f"Model       : "
        f"{best_log_loss['model']}"
    )

    print(
        f"Calibration : "
        f"{best_log_loss['calibration']}"
    )

    print(
        f"Log loss    : "
        f"{best_log_loss['log_loss']:.6f}"
    )

    # --------------------------------------------------------
    # Save summary
    # --------------------------------------------------------

    summary = {
        "best_brier_score": {
            "model":
                best_brier["model"],
            "calibration":
                best_brier["calibration"],
            "brier_score":
                float(
                    best_brier[
                        "brier_score"
                    ]
                ),
        },

        "best_log_loss": {
            "model":
                best_log_loss["model"],
            "calibration":
                best_log_loss["calibration"],
            "log_loss":
                float(
                    best_log_loss[
                        "log_loss"
                    ]
                ),
        },

        "note":
            (
                "Results are based on "
                "out-of-fold predictions "
                "from the training split. "
                "The held-out test split "
                "was not used for model "
                "selection."
            ),
    }

    with open(
        CALIBRATION_DIR /
        "calibration_summary.json",
        "w",
        encoding="utf-8",
    ) as file:

        json.dump(
            summary,
            file,
            indent=2,
        )

    print()
    print("=" * 70)
    print("ANALYSIS COMPLETE")
    print("=" * 70)

    print()
    print(
        "Reports saved to:"
    )

    print(
        CALIBRATION_DIR
    )

    print()
    print(
        "Plots saved to:"
    )

    print(
        PLOT_DIR
    )


if __name__ == "__main__":
    main()
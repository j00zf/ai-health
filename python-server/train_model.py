"""
Train the facial stress classifier.

The model expects a CSV containing facial/derived features and a real
stress label.

LABEL:
    0 = non-stress
    1 = stress

IMPORTANT:
Do NOT generate the training label from the fallback_stress_score()
inside app.py. That would only teach the model to reproduce the
same heuristic.

For a research-grade model, labels should come from a validated
stress protocol, task condition, questionnaire, or physiological
ground truth.

Example:

python train_model.py --csv data/stress_features.csv
"""

from pathlib import Path
import argparse
import json

import joblib
import numpy as np
import pandas as pd

from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)

from sklearn.model_selection import (
    GroupShuffleSplit,
    train_test_split,
)

from xgboost import XGBClassifier


FEATURES = [
    "left_eye_openness",
    "right_eye_openness",
    "eye_openness_mean",
    "eye_closure",
    "blink_count",
    "prolonged_closure",
    "visual_fatigue",
    "alertness",
    "abs_yaw",
    "abs_pitch",
    "abs_roll",
    "face_confidence",
    "face_size_ratio",
    "sample_count",
]


def load_dataset(csv_path: str):
    df = pd.read_csv(csv_path)

    required = FEATURES + ["label"]

    missing = [
        column
        for column in required
        if column not in df.columns
    ]

    if missing:
        raise ValueError(
            "Missing required columns: "
            + ", ".join(missing)
        )

    df = df.copy()

    df["label"] = (
        pd.to_numeric(
            df["label"],
            errors="coerce",
        )
    )

    df = df.dropna(
        subset=["label"]
    )

    df["label"] = (
        df["label"]
        .astype(int)
    )

    invalid_labels = sorted(
        set(df["label"].unique())
        - {0, 1}
    )

    if invalid_labels:
        raise ValueError(
            "label must contain only 0 and 1. "
            f"Found: {invalid_labels}"
        )

    X = (
        df[FEATURES]
        .apply(
            pd.to_numeric,
            errors="coerce",
        )
        .fillna(0.0)
    )

    y = df["label"]

    return df, X, y


def split_dataset(
    df,
    X,
    y,
):
    # Subject-level splitting is strongly preferred.
    # It prevents frames from the same person appearing
    # in both training and test data.
    if "subject_id" in df.columns:
        groups = df["subject_id"]

        splitter = GroupShuffleSplit(
            n_splits=1,
            test_size=0.20,
            random_state=42,
        )

        train_idx, test_idx = next(
            splitter.split(
                X,
                y,
                groups=groups,
            )
        )

        return (
            X.iloc[train_idx],
            X.iloc[test_idx],
            y.iloc[train_idx],
            y.iloc[test_idx],
        )

    train_idx, test_idx = train_test_split(
        np.arange(len(df)),
        test_size=0.20,
        stratify=y,
        random_state=42,
    )

    return (
        X.iloc[train_idx],
        X.iloc[test_idx],
        y.iloc[train_idx],
        y.iloc[test_idx],
    )


def build_model(y_train):
    positive = int(
        np.sum(y_train == 1)
    )

    negative = int(
        np.sum(y_train == 0)
    )

    scale_pos_weight = (
        negative / positive
        if positive > 0
        else 1.0
    )

    return XGBClassifier(
        n_estimators=300,
        max_depth=4,
        learning_rate=0.035,
        subsample=0.85,
        colsample_bytree=0.85,
        min_child_weight=2,
        reg_alpha=0.05,
        reg_lambda=1.0,
        objective="binary:logistic",
        eval_metric="logloss",
        scale_pos_weight=scale_pos_weight,
        random_state=42,
        n_jobs=2,
    )


def evaluate(
    model,
    X_test,
    y_test,
):
    prediction = model.predict(
        X_test
    )

    probability = model.predict_proba(
        X_test
    )[:, 1]

    metrics = {
        "accuracy": float(
            accuracy_score(
                y_test,
                prediction,
            )
        ),
        "precision": float(
            precision_score(
                y_test,
                prediction,
                zero_division=0,
            )
        ),
        "recall": float(
            recall_score(
                y_test,
                prediction,
                zero_division=0,
            )
        ),
        "f1": float(
            f1_score(
                y_test,
                prediction,
                zero_division=0,
            )
        ),
    }

    if len(
        np.unique(y_test)
    ) == 2:
        metrics["roc_auc"] = float(
            roc_auc_score(
                y_test,
                probability,
            )
        )

    print("\nClassification report:")
    print(
        classification_report(
            y_test,
            prediction,
            digits=4,
            zero_division=0,
        )
    )

    print("Confusion matrix:")
    print(
        confusion_matrix(
            y_test,
            prediction,
        )
    )

    print("\nMetrics:")
    for key, value in metrics.items():
        print(
            f"{key}: {value:.4f}"
        )

    return metrics


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--csv",
        required=True,
        help="Training CSV file.",
    )

    parser.add_argument(
        "--output",
        default="models/stress_xgb.joblib",
        help="Output model path.",
    )

    args = parser.parse_args()

    print(
        f"Loading dataset: {args.csv}"
    )

    df, X, y = load_dataset(
        args.csv
    )

    print(
        f"Rows: {len(df)}"
    )

    print(
        "Class distribution:"
    )

    print(
        y.value_counts(
            normalize=False
        ).sort_index()
    )

    if y.nunique() != 2:
        raise ValueError(
            "Training requires both classes: "
            "0=non-stress and 1=stress."
        )

    (
        X_train,
        X_test,
        y_train,
        y_test,
    ) = split_dataset(
        df,
        X,
        y,
    )

    print(
        f"Training rows: {len(X_train)}"
    )

    print(
        f"Testing rows: {len(X_test)}"
    )

    model = build_model(
        y_train
    )

    print(
        "\nTraining XGBoost..."
    )

    model.fit(
        X_train,
        y_train,
    )

    metrics = evaluate(
        model,
        X_test,
        y_test,
    )

    output_path = Path(
        args.output
    )

    output_path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    joblib.dump(
        model,
        output_path,
    )

    metadata_path = output_path.with_suffix(
        ".metadata.json"
    )

    metadata = {
        "model": "xgboost",
        "model_version": "1.0.0",
        "features": FEATURES,
        "labels": {
            "0": "non-stress",
            "1": "stress",
        },
        "metrics": metrics,
        "rows": len(df),
        "subject_split": (
            "subject_id"
            in df.columns
        ),
    }

    metadata_path.write_text(
        json.dumps(
            metadata,
            indent=2,
        ),
        encoding="utf-8",
    )

    print(
        f"\nModel saved: {output_path}"
    )

    print(
        f"Metadata saved: {metadata_path}"
    )


if __name__ == "__main__":
    main()
from __future__ import annotations

import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd

from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    average_precision_score,
    classification_report,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import StratifiedKFold, cross_validate, train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.ensemble import RandomForestClassifier

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


def make_preprocessor() -> ColumnTransformer:
    numeric_pipe = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="median")),
            ("scaler", StandardScaler()),
        ]
    )

    categorical_pipe = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="most_frequent")),
            ("onehot", OneHotEncoder(handle_unknown="ignore")),
        ]
    )

    return ColumnTransformer(
        transformers=[
            ("num", numeric_pipe, NUMERIC_FEATURES),
            ("cat", categorical_pipe, CATEGORICAL_FEATURES),
        ]
    )


def make_models():
    return {
        "logistic_regression": Pipeline(
            steps=[
                ("preprocessor", make_preprocessor()),
                (
                    "model",
                    LogisticRegression(
                        max_iter=2000,
                        class_weight="balanced",
                        random_state=RANDOM_STATE,
                    ),
                ),
            ]
        ),
        "random_forest": Pipeline(
            steps=[
                ("preprocessor", make_preprocessor()),
                (
                    "model",
                    RandomForestClassifier(
                        n_estimators=500,
                        min_samples_leaf=5,
                        class_weight="balanced",
                        random_state=RANDOM_STATE,
                        n_jobs=-1,
                    ),
                ),
            ]
        ),
    }


def evaluate_cv(models, X_train, y_train):
    cv = StratifiedKFold(
        n_splits=CV_FOLDS,
        shuffle=True,
        random_state=RANDOM_STATE,
    )

    rows = []

    for name, pipeline in models.items():
        scores = cross_validate(
            pipeline,
            X_train,
            y_train,
            cv=cv,
            scoring={
                "roc_auc": "roc_auc",
                "average_precision": "average_precision",
                "accuracy": "accuracy",
                "precision": "precision",
                "recall": "recall",
                "f1": "f1",
            },
            n_jobs=-1,
        )

        rows.append(
            {
                "model": name,
                "roc_auc_mean": float(np.mean(scores["test_roc_auc"])),
                "roc_auc_std": float(np.std(scores["test_roc_auc"])),
                "pr_auc_mean": float(np.mean(scores["test_average_precision"])),
                "accuracy_mean": float(np.mean(scores["test_accuracy"])),
                "precision_mean": float(np.mean(scores["test_precision"])),
                "recall_mean": float(np.mean(scores["test_recall"])),
                "f1_mean": float(np.mean(scores["test_f1"])),
            }
        )

    return pd.DataFrame(rows).sort_values("roc_auc_mean", ascending=False)


def evaluate_test(model, X_test, y_test):
    predictions = model.predict(X_test)
    probabilities = model.predict_proba(X_test)[:, 1]

    cm = confusion_matrix(y_test, predictions)

    metrics = {
        "roc_auc": float(roc_auc_score(y_test, probabilities)),
        "pr_auc": float(average_precision_score(y_test, probabilities)),
        "accuracy": float(accuracy_score(y_test, predictions)),
        "precision": float(precision_score(y_test, predictions, zero_division=0)),
        "recall": float(recall_score(y_test, predictions, zero_division=0)),
        "f1": float(f1_score(y_test, predictions, zero_division=0)),
        "confusion_matrix": cm.tolist(),
        "classification_report": classification_report(
            y_test, predictions, output_dict=True, zero_division=0
        ),
    }

    return metrics


def save_feature_importance(model, output_path: Path):
    estimator = model.named_steps["model"]
    preprocessor = model.named_steps["preprocessor"]

    feature_names = preprocessor.get_feature_names_out()

    if hasattr(estimator, "coef_"):
        importance = np.abs(estimator.coef_[0])
    elif hasattr(estimator, "feature_importances_"):
        importance = estimator.feature_importances_
    else:
        return

    result = (
        pd.DataFrame({"feature": feature_names, "importance": importance})
        .sort_values("importance", ascending=False)
        .reset_index(drop=True)
    )
    result.to_csv(output_path, index=False)


def main():
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)

    print(f"Loading: {DATA_PATH}")
    df = clean_basic(load_dataset())

    print(f"Rows after basic cleaning: {len(df)}")
    print(f"Positive target rate: {df[TARGET].mean():.4f}")

    X = df[FEATURES]
    y = df[TARGET].astype(int)

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=TEST_SIZE,
        stratify=y,
        random_state=RANDOM_STATE,
    )

    models = make_models()

    cv_results = evaluate_cv(models, X_train, y_train)
    print("\nCross-validation results:")
    print(cv_results.to_string(index=False))

    cv_results.to_csv(REPORT_DIR / "cv_results.csv", index=False)

    best_name = cv_results.iloc[0]["model"]
    best_model = models[best_name]

    print(f"\nSelected model: {best_name}")
    best_model.fit(X_train, y_train)

    test_metrics = evaluate_test(best_model, X_test, y_test)

    print("\nHeld-out test metrics:")
    for key in ["roc_auc", "pr_auc", "accuracy", "precision", "recall", "f1"]:
        print(f"{key:>10}: {test_metrics[key]:.4f}")

    pd.DataFrame(
        test_metrics["confusion_matrix"],
        index=["actual_0", "actual_1"],
        columns=["predicted_0", "predicted_1"],
    ).to_csv(REPORT_DIR / "confusion_matrix.csv")

    with open(REPORT_DIR / "test_metrics.json", "w", encoding="utf-8") as f:
        json.dump(test_metrics, f, indent=2)

    save_feature_importance(
        best_model,
        REPORT_DIR / "feature_importance.csv",
    )

    joblib.dump(best_model, MODEL_DIR / "heart_risk_model.joblib")

    metadata = {
        "model_name": best_name,
        "target": TARGET,
        "features": FEATURES,
        "random_state": RANDOM_STATE,
        "test_size": TEST_SIZE,
        "cv_folds": CV_FOLDS,
        "positive_target_rate": float(y.mean()),
        "test_metrics": {
            key: value
            for key, value in test_metrics.items()
            if key != "classification_report"
        },
    }

    with open(MODEL_DIR / "model_metadata.json", "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)

    print("\nSaved:")
    print(f"  {MODEL_DIR / 'heart_risk_model.joblib'}")
    print(f"  {MODEL_DIR / 'model_metadata.json'}")
    print(f"  {REPORT_DIR / 'cv_results.csv'}")
    print(f"  {REPORT_DIR / 'test_metrics.json'}")
    print(f"  {REPORT_DIR / 'confusion_matrix.csv'}")
    print(f"  {REPORT_DIR / 'feature_importance.csv'}")


if __name__ == "__main__":
    main()

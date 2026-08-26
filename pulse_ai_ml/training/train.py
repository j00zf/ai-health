from pathlib import Path
import json

import joblib
import pandas as pd

from sklearn.model_selection import (
    train_test_split
)

from sklearn.impute import (
    SimpleImputer
)

from sklearn.pipeline import (
    Pipeline
)

from sklearn.metrics import (
    roc_auc_score,
    average_precision_score,
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    brier_score_loss,
    confusion_matrix,
)

from xgboost import XGBClassifier


# ============================================================
# PATHS
# ============================================================

ROOT = (
    Path(__file__)
    .resolve()
    .parents[1]
)


DATA_FILE = (
    ROOT
    / "data"
    / "pulse_training_dataset.parquet"
)


MODEL_DIR = (
    ROOT
    / "models"
)


ARTIFACT_DIR = (
    ROOT
    / "artifacts"
)


MODEL_DIR.mkdir(
    exist_ok=True
)


ARTIFACT_DIR.mkdir(
    exist_ok=True
)


# ============================================================
# FEATURES
# ============================================================

FEATURES = [

    "age",

    "sex",

    "height_cm",

    "weight_kg",

    "bmi",

    "waist_cm",

    "heart_rate",

    "systolic_bp",

    "diastolic_bp",

    "activity_minutes",

    "sleep_hours",

    "smoking",

    "alcohol",
]


# ============================================================
# TARGETS
# ============================================================

TARGETS = {

    "heart": "heart_outcome",

    "health": "health_outcome",

    "wellness": "wellness_outcome",
}


# ============================================================
# TRAIN ONE MODEL
# ============================================================

def train_model(
    df,
    target_name,
    model_name
):

    print(
        "\n"
        + "=" * 70
    )


    print(
        f"TRAINING {model_name.upper()} MODEL"
    )


    print(
        "=" * 70
    )


    # --------------------------------------------------------
    # Remove missing target
    # --------------------------------------------------------

    data = df.dropna(
        subset=[
            target_name
        ]
    ).copy()


    X = data[
        FEATURES
    ]


    y = (
        data[
            target_name
        ]
        .astype(int)
    )


    print(
        f"\nRows: {len(data):,}"
    )


    print(
        "\nTarget distribution:"
    )


    print(
        y.value_counts()
    )


    print(
        "\nTarget percentage:"
    )


    print(
        y.value_counts(
            normalize=True
        )
        .mul(100)
        .round(2)
    )


    # --------------------------------------------------------
    # Split
    # --------------------------------------------------------

    X_train, X_test, y_train, y_test = (
        train_test_split(

            X,

            y,

            test_size=0.20,

            random_state=42,

            stratify=y,
        )
    )


    # --------------------------------------------------------
    # Class balance
    # --------------------------------------------------------

    positive = (
        y_train == 1
    ).sum()


    negative = (
        y_train == 0
    ).sum()


    scale_pos_weight = (
        negative
        /
        max(
            positive,
            1
        )
    )


    # --------------------------------------------------------
    # XGBoost
    # --------------------------------------------------------

    model = XGBClassifier(

        n_estimators=450,

        max_depth=4,

        learning_rate=0.035,

        subsample=0.85,

        colsample_bytree=0.85,

        min_child_weight=5,

        gamma=0.1,

        reg_alpha=0.2,

        reg_lambda=2.0,

        objective="binary:logistic",

        eval_metric="logloss",

        scale_pos_weight=scale_pos_weight,

        random_state=42,

        n_jobs=-1,
    )


    # --------------------------------------------------------
    # Pipeline
    # --------------------------------------------------------

    pipeline = Pipeline([

        (
            "imputer",

            SimpleImputer(

                strategy="median",

                add_indicator=True
            )
        ),

        (
            "model",

            model
        ),

    ])


    print(
        "\nTraining..."
    )


    pipeline.fit(
        X_train,
        y_train
    )


    # --------------------------------------------------------
    # Predictions
    # --------------------------------------------------------

    probabilities = (
        pipeline
        .predict_proba(
            X_test
        )[:, 1]
    )


    predictions = (
        probabilities >= 0.50
    ).astype(int)


    # --------------------------------------------------------
    # Metrics
    # --------------------------------------------------------

    metrics = {

        "model": model_name,

        "target": target_name,

        "features": FEATURES,

        "train_rows": int(
            len(X_train)
        ),

        "test_rows": int(
            len(X_test)
        ),

        "roc_auc": float(
            roc_auc_score(
                y_test,
                probabilities
            )
        ),

        "average_precision": float(
            average_precision_score(
                y_test,
                probabilities
            )
        ),

        "accuracy": float(
            accuracy_score(
                y_test,
                predictions
            )
        ),

        "precision": float(
            precision_score(
                y_test,
                predictions,
                zero_division=0
            )
        ),

        "recall": float(
            recall_score(
                y_test,
                predictions,
                zero_division=0
            )
        ),

        "f1": float(
            f1_score(
                y_test,
                predictions,
                zero_division=0
            )
        ),

        "brier_score": float(
            brier_score_loss(
                y_test,
                probabilities
            )
        ),

        "confusion_matrix":
            confusion_matrix(
                y_test,
                predictions
            ).tolist(),
    }


    # --------------------------------------------------------
    # Save
    # --------------------------------------------------------

    model_path = (
        MODEL_DIR
        /
        f"pulse_{model_name.lower()}_v1.joblib"
    )


    joblib.dump(
        pipeline,
        model_path
    )


    print(
        "\nMetrics:"
    )


    print(
        f"ROC-AUC:           "
        f"{metrics['roc_auc']:.4f}"
    )


    print(
        f"Average Precision: "
        f"{metrics['average_precision']:.4f}"
    )


    print(
        f"Accuracy:          "
        f"{metrics['accuracy']:.4f}"
    )


    print(
        f"Precision:         "
        f"{metrics['precision']:.4f}"
    )


    print(
        f"Recall:            "
        f"{metrics['recall']:.4f}"
    )


    print(
        f"F1:                "
        f"{metrics['f1']:.4f}"
    )


    print(
        f"Brier Score:      "
        f"{metrics['brier_score']:.4f}"
    )


    print(
        f"\nSaved:"
    )


    print(
        model_path
    )


    return {

        "pipeline": pipeline,

        "metrics": metrics,

        "model_path": str(
            model_path
        ),
    }


# ============================================================
# MAIN
# ============================================================

def main():

    print(
        "\nLoading training dataset..."
    )


    if not DATA_FILE.exists():

        raise FileNotFoundError(
            f"\nDataset not found:\n"
            f"{DATA_FILE}\n\n"
            "Run:\n"
            "python training\\prepare_dataset.py"
        )


    df = pd.read_parquet(
        DATA_FILE
    )


    print(
        f"Dataset shape: {df.shape}"
    )


    # --------------------------------------------------------
    # Verify features
    # --------------------------------------------------------

    missing_features = [
        feature
        for feature in FEATURES
        if feature not in df.columns
    ]


    if missing_features:

        raise ValueError(
            "\nMissing features:\n"
            +
            "\n".join(
                f"  - {feature}"
                for feature in missing_features
            )
        )


    # --------------------------------------------------------
    # Train all three models
    # --------------------------------------------------------

    heart = train_model(
        df,

        TARGETS["heart"],

        "Heart"
    )


    health = train_model(
        df,

        TARGETS["health"],

        "Health"
    )


    wellness = train_model(
        df,

        TARGETS["wellness"],

        "Wellness"
    )


    # ========================================================
    # MODEL METADATA
    # ========================================================

    metadata = {

        "version":
            "pulse-health-wellness-v1",

        "dataset":
            "NHANES 2017-March 2020",

        "features":
            FEATURES,

        "models": {

            "heart": {
                "target":
                    TARGETS["heart"],

                "artifact":
                    heart["model_path"],
            },

            "health": {
                "target":
                    TARGETS["health"],

                "artifact":
                    health["model_path"],
            },

            "wellness": {
                "target":
                    TARGETS["wellness"],

                "artifact":
                    wellness["model_path"],
            },
        },

        "score_definition": {

            "heart_health_score":
                "100 * (1 - heart risk probability)",

            "health_score":
                "100 * (1 - health risk probability)",

            "wellness_score":
                "100 * favorable wellness probability",

            "overall_score":
                "weighted combination of heart, health and wellness",
        },

        "disclaimer":
            "Research/decision-support scores. "
            "Not medical diagnoses."
    }


    # --------------------------------------------------------
    # Save metadata
    # --------------------------------------------------------

    metadata_path = (
        ARTIFACT_DIR
        /
        "model_metadata.json"
    )


    metadata_path.write_text(
        json.dumps(
            metadata,
            indent=2
        )
    )


    # --------------------------------------------------------
    # Save metrics
    # --------------------------------------------------------

    metrics = {

        "heart": heart["metrics"],

        "health": health["metrics"],

        "wellness": wellness["metrics"],
    }


    metrics_path = (
        ARTIFACT_DIR
        /
        "training_metrics.json"
    )


    metrics_path.write_text(
        json.dumps(
            metrics,
            indent=2
        )
    )


    # ========================================================
    # FINAL REPORT
    # ========================================================

    print(
        "\n"
        + "=" * 70
    )


    print(
        "PULSE AI MULTI-MODEL TRAINING COMPLETE"
    )


    print(
        "=" * 70
    )


    print(
        "\nModels:"
    )


    print(
        "  ❤️  Heart Health Model"
    )


    print(
        "  🏥 Health Model"
    )


    print(
        "  🌿 Wellness Model"
    )


    print(
        "\nArtifacts:"
    )


    print(
        metadata_path
    )


    print(
        metrics_path
    )


if __name__ == "__main__":

    main()
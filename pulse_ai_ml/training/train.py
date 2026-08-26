from pathlib import Path
import json

import joblib
import pandas as pd

from sklearn.model_selection import train_test_split

from sklearn.impute import SimpleImputer

from sklearn.pipeline import Pipeline

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
    parents=True,
    exist_ok=True
)


ARTIFACT_DIR.mkdir(
    parents=True,
    exist_ok=True
)


# ============================================================
# DEPLOYMENT FEATURES
# ============================================================

FEATURES = [

    "age",
    "sex",

    "height_cm",
    "weight_kg",
    "bmi",
    "waist_cm",

    "heart_rate",

    "activity_minutes",

    "sleep_hours",

    "smoking",
    "alcohol",
]


# ============================================================
# TARGETS
# ============================================================

TARGETS = {

    "heart":
        "heart_outcome",

    "health":
        "health_outcome",

    "wellness":
        "wellness_outcome",
}


# ============================================================
# MODEL FILES
# ============================================================

MODEL_FILES = {

    "heart":
        "pulse_heart_v2_deployment.joblib",

    "health":
        "pulse_health_v2_deployment.joblib",

    "wellness":
        "pulse_wellness_v2_deployment.joblib",
}


# ============================================================
# TRAIN ONE MODEL
# ============================================================

def train_model(
    df,
    target_name,
    model_name,
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
    # Remove rows with unavailable target
    # --------------------------------------------------------

    data = df.dropna(
        subset=[
            target_name
        ]
    ).copy()


    X = data[
        FEATURES
    ].copy()


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
        "\nFeatures:"
    )


    for feature in FEATURES:

        print(
            f"  ✓ {feature}"
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
    # Missingness
    # --------------------------------------------------------

    print(
        "\nFeature missingness:"
    )


    missingness = (
        X.isna()
        .mean()
        .mul(100)
        .round(2)
        .sort_values(
            ascending=False
        )
    )


    print(
        missingness
    )


    # --------------------------------------------------------
    # Train / test split
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
    # Class imbalance
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


    print(
        "\nClass weight:",
        round(
            scale_pos_weight,
            4
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


    # --------------------------------------------------------
    # Train
    # --------------------------------------------------------

    print(
        "\nTraining XGBoost..."
    )


    pipeline.fit(
        X_train,
        y_train
    )


    print(
        "Training complete."
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

        "model":
            model_name,

        "version":
            "v2-deployment",

        "target":
            target_name,

        "blood_pressure_used":
            False,

        "features":
            FEATURES,

        "train_rows":
            int(
                len(X_train)
            ),

        "test_rows":
            int(
                len(X_test)
            ),

        "roc_auc":
            float(
                roc_auc_score(
                    y_test,
                    probabilities
                )
            ),

        "average_precision":
            float(
                average_precision_score(
                    y_test,
                    probabilities
                )
            ),

        "accuracy":
            float(
                accuracy_score(
                    y_test,
                    predictions
                )
            ),

        "precision":
            float(
                precision_score(
                    y_test,
                    predictions,
                    zero_division=0
                )
            ),

        "recall":
            float(
                recall_score(
                    y_test,
                    predictions,
                    zero_division=0
                )
            ),

        "f1":
            float(
                f1_score(
                    y_test,
                    predictions,
                    zero_division=0
                )
            ),

        "brier_score":
            float(
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
    # Save model
    # --------------------------------------------------------

    model_key = (
        model_name
        .lower()
    )


    model_path = (
        MODEL_DIR
        /
        MODEL_FILES[
            model_key
        ]
    )


    joblib.dump(
        pipeline,
        model_path
    )


    # --------------------------------------------------------
    # Report
    # --------------------------------------------------------

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
        "\nConfusion Matrix:"
    )


    print(
        confusion_matrix(
            y_test,
            predictions
        )
    )


    print(
        "\nSaved:"
    )


    print(
        model_path
    )


    return {

        "metrics":
            metrics,

        "model_path":
            str(
                model_path
            ),
    }


# ============================================================
# MAIN
# ============================================================

def main():

    print(
        "\n"
        "============================================================\n"
        "PULSE AI DEPLOYMENT-COMPATIBLE ML TRAINING\n"
        "============================================================"
    )


    # --------------------------------------------------------
    # Check dataset
    # --------------------------------------------------------

    if not DATA_FILE.exists():

        raise FileNotFoundError(
            f"\nDataset not found:\n"
            f"{DATA_FILE}\n\n"
            f"Run:\n"
            f"python training\\prepare_dataset.py"
        )


    # --------------------------------------------------------
    # Load
    # --------------------------------------------------------

    print(
        "\nLoading training dataset..."
    )


    df = pd.read_parquet(
        DATA_FILE
    )


    print(
        f"Dataset shape: {df.shape}"
    )


    # --------------------------------------------------------
    # Validate features
    # --------------------------------------------------------

    missing_features = [

        feature

        for feature in FEATURES

        if feature not in df.columns
    ]


    if missing_features:

        raise ValueError(
            "\nMissing deployment features:\n"
            +
            "\n".join(
                f"  - {feature}"
                for feature in missing_features
            )
        )


    # --------------------------------------------------------
    # Explicit BP safety check
    # --------------------------------------------------------

    if "systolic_bp" in FEATURES:

        raise RuntimeError(
            "systolic_bp is forbidden "
            "in the deployment model."
        )


    if "diastolic_bp" in FEATURES:

        raise RuntimeError(
            "diastolic_bp is forbidden "
            "in the deployment model."
        )


    print(
        "\nDeployment feature set:"
    )


    for feature in FEATURES:

        print(
            f"  ✓ {feature}"
        )


    print(
        "\nBP dependency:"
    )


    print(
        "  ✗ systolic_bp"
    )


    print(
        "  ✗ diastolic_bp"
    )


    # ========================================================
    # TRAIN HEART
    # ========================================================

    heart = train_model(

        df,

        TARGETS["heart"],

        "Heart"
    )


    # ========================================================
    # TRAIN HEALTH
    # ========================================================

    health = train_model(

        df,

        TARGETS["health"],

        "Health"
    )


    # ========================================================
    # TRAIN WELLNESS
    # ========================================================

    wellness = train_model(

        df,

        TARGETS["wellness"],

        "Wellness"
    )


    # ========================================================
    # SAVE METADATA
    # ========================================================

    metadata = {

        "project":
            "Pulse AI",

        "version":
            "pulse-health-wellness-v2",

        "deployment_compatible":
            True,

        "blood_pressure_used":
            False,

        "dataset":
            "NHANES 2017-March 2020",

        "features":
            FEATURES,

        "targets":
            TARGETS,

        "models": {

            "heart":
                heart["model_path"],

            "health":
                health["model_path"],

            "wellness":
                wellness["model_path"],
        },

        "output_scores": [

            "heartHealthScore",

            "healthScore",

            "wellnessScore",

            "overallWellbeingScore",
        ],

        "score_semantics": {

            "heartHealthScore":
                "Higher indicates a more favorable "
                "model-based cardiovascular outcome profile.",

            "healthScore":
                "Higher indicates a more favorable "
                "model-based cardiometabolic health profile.",

            "wellnessScore":
                "Higher indicates a higher probability "
                "of favorable self-rated general health.",

            "overallWellbeingScore":
                "Combined product-level score generated "
                "from the three dimensions and personal "
                "longitudinal wellness signals.",
        },

        "important_note":
            "These models are research and decision-support "
            "models and are not medical diagnostic tools.",
    }


    metadata_path = (
        ARTIFACT_DIR
        /
        "deployment_model_metadata.json"
    )


    metadata_path.write_text(
        json.dumps(
            metadata,
            indent=2
        )
    )


    # ========================================================
    # SAVE METRICS
    # ========================================================

    metrics = {

        "heart":
            heart["metrics"],

        "health":
            health["metrics"],

        "wellness":
            wellness["metrics"],
    }


    metrics_path = (
        ARTIFACT_DIR
        /
        "deployment_training_metrics.json"
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
        "DEPLOYMENT-COMPATIBLE TRAINING COMPLETE"
    )


    print(
        "=" * 70
    )


    print(
        "\n❤️ Heart model:"
    )


    print(
        heart["model_path"]
    )


    print(
        "\n🏥 Health model:"
    )


    print(
        health["model_path"]
    )


    print(
        "\n🌿 Wellness model:"
    )


    print(
        wellness["model_path"]
    )


    print(
        "\nMetadata:"
    )


    print(
        metadata_path
    )


    print(
        "\nMetrics:"
    )


    print(
        metrics_path
    )


# ============================================================
# ENTRY POINT
# ============================================================

if __name__ == "__main__":

    main()
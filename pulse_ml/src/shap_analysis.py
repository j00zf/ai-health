import os
import json
import joblib
import numpy as np
import pandas as pd
import shap
import matplotlib.pyplot as plt


# ============================================================================
# CONFIGURATION
# ============================================================================

MODEL_PATH = "../models/advanced/xgboost.pkl"
TEST_FILE = "../models/advanced/test.csv"

OUTPUT_DIR = "../reports/shap"

os.makedirs(
    OUTPUT_DIR,
    exist_ok=True,
)


FEATURES = [
    "age_years",
    "sex",
    "height",
    "weight",
    "bmi",
    "smoke",
    "alco",
    "active",
    "ap_hi",
    "ap_lo",
    "cholesterol",
]


# ============================================================================
# SHAP COMPATIBILITY PATCH
# ============================================================================
#
# XGBoost 3.x can store base_score as:
#
#     "[4.996875E-1]"
#
# SHAP 0.49.1 expects:
#
#     "4.996875E-1"
#
# We make a temporary in-memory copy of the booster and normalize the
# base_score representation before passing it to SHAP.
#
# The original trained model is NOT modified or overwritten.
# ============================================================================


def create_shap_compatible_model(model):

    print(
        "\nPreparing XGBoost model for SHAP..."
    )

    booster = model.get_booster()

    # Save booster temporarily in JSON format.
    temp_json = (
        "../reports/"
        "shap_compatible_xgb.json"
    )

    booster.save_model(
        temp_json
    )

    # Read JSON.
    with open(
        temp_json,
        "r",
        encoding="utf-8",
    ) as file:

        model_json = json.load(
            file
        )

    # ------------------------------------------------------------------------
    # Locate learner parameters
    # ------------------------------------------------------------------------

    learner = model_json.get(
        "learner"
    )

    if learner is None:

        raise RuntimeError(
            "Could not locate 'learner' "
            "inside XGBoost JSON model."
        )

    learner_model_param = learner.get(
        "learner_model_param"
    )

    if learner_model_param is None:

        raise RuntimeError(
            "Could not locate "
            "'learner_model_param' "
            "inside XGBoost JSON model."
        )

    # ------------------------------------------------------------------------
    # Normalize base_score
    # ------------------------------------------------------------------------

    base_score = learner_model_param.get(
        "base_score"
    )

    print(
        f"Original base_score: "
        f"{base_score}"
    )

    if isinstance(
        base_score,
        str,
    ):

        cleaned = (
            base_score
            .strip()
            .strip("[")
            .strip("]")
        )

        # If multiple values somehow exist,
        # take the first one for binary classification.

        if "," in cleaned:

            cleaned = (
                cleaned
                .split(",")[0]
                .strip()
            )

        learner_model_param[
            "base_score"
        ] = cleaned

    print(
        "SHAP-compatible base_score: "
        f"{learner_model_param['base_score']}"
    )

    # ------------------------------------------------------------------------
    # Save patched JSON
    # ------------------------------------------------------------------------

    patched_json = (
        "../reports/"
        "shap_compatible_xgb_patched.json"
    )

    with open(
        patched_json,
        "w",
        encoding="utf-8",
    ) as file:

        json.dump(
            model_json,
            file,
            indent=2,
        )

    # ------------------------------------------------------------------------
    # Load patched booster
    # ------------------------------------------------------------------------

    import xgboost as xgb

    compatible_booster = (
        xgb.Booster()
    )

    compatible_booster.load_model(
        patched_json
    )

    return compatible_booster


# ============================================================================
# MAIN
# ============================================================================


def main():

    print("=" * 80)
    print(
        "PULSE AI ADVANCED — SHAP ANALYSIS"
    )
    print("=" * 80)

    # ========================================================================
    # LOAD MODEL
    # ========================================================================

    print(
        "\nLoading XGBoost model..."
    )

    model = joblib.load(
        MODEL_PATH
    )

    print(
        f"Model type: {type(model)}"
    )

    # ========================================================================
    # LOAD DATA
    # ========================================================================

    print(
        "Loading test data..."
    )

    df = pd.read_csv(
        TEST_FILE
    )

    X = df[
        FEATURES
    ]

    y = df[
        "cardio"
    ]

    print(
        f"Test records: {len(X)}"
    )

    # ========================================================================
    # VERIFY MODEL
    # ========================================================================

    print(
        "\nTesting original model..."
    )

    original_probability = (
        model.predict_proba(X)[:, 1]
    )

    print(
        "Original probability range:"
    )

    print(
        f"  min = "
        f"{original_probability.min():.6f}"
    )

    print(
        f"  max = "
        f"{original_probability.max():.6f}"
    )

    # ========================================================================
    # SAMPLE
    # ========================================================================

    sample_size = min(
        5000,
        len(X),
    )

    X_sample = X.sample(
        n=sample_size,
        random_state=42,
    )

    print(
        f"\nSHAP sample size: "
        f"{len(X_sample)}"
    )

    # ========================================================================
    # CREATE COMPATIBLE BOOSTER
    # ========================================================================

    booster = create_shap_compatible_model(
        model
    )

    # ========================================================================
    # SHAP EXPLAINER
    # ========================================================================

    print(
        "\nCreating SHAP TreeExplainer..."
    )

    explainer = shap.TreeExplainer(
        booster
    )

    print(
        "TreeExplainer created successfully."
    )

    # ========================================================================
    # CALCULATE SHAP
    # ========================================================================

    print(
        "\nCalculating SHAP values..."
    )

    shap_values = (
        explainer.shap_values(
            X_sample
        )
    )

    shap_values = np.asarray(
        shap_values
    )

    print(
        "SHAP output shape:"
    )

    print(
        shap_values.shape
    )

    # ========================================================================
    # HANDLE OUTPUT FORMAT
    # ========================================================================

    if shap_values.ndim == 3:

        print(
            "Detected 3-dimensional SHAP output."
        )

        shap_values = (
            shap_values[:, :, -1]
        )

    if shap_values.ndim != 2:

        raise RuntimeError(
            "Unexpected SHAP output shape: "
            f"{shap_values.shape}"
        )

    if (
        shap_values.shape[1]
        != len(FEATURES)
    ):

        raise RuntimeError(
            "SHAP feature count mismatch.\n"
            f"SHAP: "
            f"{shap_values.shape[1]}\n"
            f"Expected: "
            f"{len(FEATURES)}"
        )

    # ========================================================================
    # GLOBAL FEATURE IMPORTANCE
    # ========================================================================

    print(
        "\nCalculating global feature importance..."
    )

    mean_abs_shap = (
        np.abs(
            shap_values
        )
        .mean(
            axis=0
        )
    )

    importance_df = pd.DataFrame(
        {
            "feature": FEATURES,
            "mean_abs_shap": mean_abs_shap,
        }
    )

    importance_df = (
        importance_df
        .sort_values(
            "mean_abs_shap",
            ascending=False,
        )
        .reset_index(
            drop=True
        )
    )

    importance_df.insert(
        0,
        "rank",
        range(
            1,
            len(importance_df) + 1,
        ),
    )

    # ========================================================================
    # PRINT
    # ========================================================================

    print("\n")
    print("=" * 80)
    print(
        "GLOBAL FEATURE IMPORTANCE"
    )
    print("=" * 80)

    print(
        importance_df.to_string(
            index=False
        )
    )

    # ========================================================================
    # SAVE CSV
    # ========================================================================

    importance_df.to_csv(
        f"{OUTPUT_DIR}/"
        "global_feature_importance.csv",
        index=False,
    )

    # ========================================================================
    # BAR PLOT
    # ========================================================================

    print(
        "\nGenerating importance plot..."
    )

    shap.summary_plot(
        shap_values,
        X_sample,
        feature_names=FEATURES,
        plot_type="bar",
        show=False,
    )

    plt.title(
        "Pulse AI Advanced v1 — "
        "Global Feature Importance"
    )

    plt.tight_layout()

    plt.savefig(
        f"{OUTPUT_DIR}/"
        "global_feature_importance.png",
        dpi=200,
        bbox_inches="tight",
    )

    plt.close()

    # ========================================================================
    # BEESWARM
    # ========================================================================

    print(
        "Generating SHAP summary plot..."
    )

    shap.summary_plot(
        shap_values,
        X_sample,
        feature_names=FEATURES,
        show=False,
    )

    plt.title(
        "Pulse AI Advanced v1 — "
        "SHAP Feature Contributions"
    )

    plt.tight_layout()

    plt.savefig(
        f"{OUTPUT_DIR}/"
        "shap_summary.png",
        dpi=200,
        bbox_inches="tight",
    )

    plt.close()

    # ========================================================================
    # SAVE RAW SHAP VALUES
    # ========================================================================

    shap_df = pd.DataFrame(
        shap_values,
        columns=FEATURES,
    )

    shap_df.to_csv(
        f"{OUTPUT_DIR}/"
        "shap_values.csv",
        index=False,
    )

    # ========================================================================
    # SAVE SAMPLE
    # ========================================================================

    X_sample.to_csv(
        f"{OUTPUT_DIR}/"
        "shap_sample.csv",
        index=False,
    )

    # ========================================================================
    # CLEAN TEMPORARY FILES
    # ========================================================================

    for filename in [
        "../reports/"
        "shap_compatible_xgb.json",

        "../reports/"
        "shap_compatible_xgb_patched.json",
    ]:

        if os.path.exists(
            filename
        ):

            os.remove(
                filename
            )

    # ========================================================================
    # COMPLETE
    # ========================================================================

    print("\n")
    print("=" * 80)
    print(
        "SHAP ANALYSIS COMPLETE"
    )
    print("=" * 80)

    print(
        "\nGenerated:"
    )

    print(
        "  global_feature_importance.csv"
    )

    print(
        "  global_feature_importance.png"
    )

    print(
        "  shap_summary.png"
    )

    print(
        "  shap_values.csv"
    )

    print(
        "  shap_sample.csv"
    )

    print(
        "\nSaved to:"
    )

    print(
        os.path.abspath(
            OUTPUT_DIR
        )
    )


if __name__ == "__main__":
    main()
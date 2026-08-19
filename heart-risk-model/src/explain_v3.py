from __future__ import annotations

import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd

from .config import (
    FEATURES,
    MODEL_DIR,
    REPORT_DIR,
)


# ============================================================
# PATHS
# ============================================================

MODEL_PATH = (
    MODEL_DIR /
    "heart_risk_model_v3_calibrated.joblib"
)

V3_REPORT_DIR = REPORT_DIR / "v3"

EXPLAIN_DIR = (
    V3_REPORT_DIR /
    "explainability"
)

EXPLAIN_DIR.mkdir(
    parents=True,
    exist_ok=True,
)


# ============================================================
# LOAD MODEL
# ============================================================

def load_model():

    if not MODEL_PATH.exists():

        raise FileNotFoundError(
            f"Model not found:\n{MODEL_PATH}"
        )

    print(
        f"Loading model:\n{MODEL_PATH}"
    )

    return joblib.load(
        MODEL_PATH
    )


# ============================================================
# GET BASE ESTIMATORS
# ============================================================

def get_base_estimators(model):

    if hasattr(
        model,
        "calibrated_classifiers_"
    ):

        estimators = []

        for calibrated_classifier in (
            model.calibrated_classifiers_
        ):

            estimators.append(
                calibrated_classifier.estimator
            )

        return estimators

    return [model]


# ============================================================
# FEATURE NAME CLEANING
# ============================================================

def get_transformed_feature_names(
    pipeline
):

    preprocessor = (
        pipeline.named_steps[
            "preprocessor"
        ]
    )

    return list(
        preprocessor.get_feature_names_out()
    )


def original_feature_name(
    transformed_name
):

    """
    Convert transformed sklearn feature names
    back to their original feature.

    Examples:

        numeric__age
            -> age

        categorical__diabetes_0.0
            -> diabetes

        categorical__male_1.0
            -> male

        numeric__missingindicator_BMI
            -> BMI
    """

    name = transformed_name

    if "__" in name:

        name = name.split(
            "__",
            1
        )[1]

    # Missing indicator
    if name.startswith(
        "missingindicator_"
    ):

        name = name.replace(
            "missingindicator_",
            "",
            1,
        )

        return name

    # Categorical one-hot variables
    for feature in FEATURES:

        if name == feature:
            return feature

        prefix = feature + "_"

        if name.startswith(prefix):

            return feature

    return name


# ============================================================
# EXTRACT MODEL COEFFICIENTS
# ============================================================

def extract_coefficients(model):

    estimators = (
        get_base_estimators(
            model
        )
    )

    tables = []

    for estimator in estimators:

        logistic_model = (
            estimator.named_steps[
                "model"
            ]
        )

        coefficients = (
            logistic_model.coef_[0]
        )

        feature_names = (
            get_transformed_feature_names(
                estimator
            )
        )

        table = pd.DataFrame(
            {
                "transformed_feature":
                    feature_names,

                "coefficient":
                    coefficients,
            }
        )

        table[
            "original_feature"
        ] = table[
            "transformed_feature"
        ].apply(
            original_feature_name
        )

        tables.append(
            table
        )

    combined = pd.concat(
        tables,
        ignore_index=True,
    )

    # Average coefficients across
    # calibration estimators.
    result = (
        combined
        .groupby(
            [
                "original_feature",
                "transformed_feature",
            ],
            as_index=False,
        )[
            "coefficient"
        ]
        .mean()
    )

    result[
        "absolute_coefficient"
    ] = (
        result[
            "coefficient"
        ].abs()
    )

    return result


# ============================================================
# GLOBAL FEATURE IMPORTANCE
# ============================================================

def aggregate_global_importance(
    coefficient_df
):

    result = (
        coefficient_df
        .groupby(
            "original_feature",
            as_index=False,
        )
        .agg(
            total_absolute_coefficient=(
                "absolute_coefficient",
                "sum",
            ),

            maximum_absolute_coefficient=(
                "absolute_coefficient",
                "max",
            ),
        )
    )

    result = (
        result
        .sort_values(
            "total_absolute_coefficient",
            ascending=False,
        )
        .reset_index(
            drop=True
        )
    )

    result[
        "rank"
    ] = (
        np.arange(
            len(result)
        ) + 1
    )

    return result


# ============================================================
# INDIVIDUAL CONTRIBUTIONS
# ============================================================

def explain_prediction(
    model,
    user_data,
):

    X = pd.DataFrame(
        [user_data]
    )

    probability = float(
        model.predict_proba(
            X
        )[0, 1]
    )

    estimators = (
        get_base_estimators(
            model
        )
    )

    # We calculate the explanation for
    # every calibrated base estimator and
    # average the contributions.
    all_contributions = []

    for estimator in estimators:

        preprocessor = (
            estimator.named_steps[
                "preprocessor"
            ]
        )

        logistic_model = (
            estimator.named_steps[
                "model"
            ]
        )

        transformed = (
            preprocessor.transform(
                X
            )
        )

        feature_names = (
            get_transformed_feature_names(
                estimator
            )
        )

        coefficients = (
            logistic_model.coef_[0]
        )

        contributions = (
            transformed[0] *
            coefficients
        )

        contribution_df = pd.DataFrame(
            {
                "transformed_feature":
                    feature_names,

                "contribution":
                    contributions,
            }
        )

        contribution_df[
            "original_feature"
        ] = contribution_df[
            "transformed_feature"
        ].apply(
            original_feature_name
        )

        all_contributions.append(
            contribution_df
        )

    combined = pd.concat(
        all_contributions,
        ignore_index=True,
    )

    # --------------------------------------------------------
    # Aggregate transformed features into original features
    # --------------------------------------------------------

    aggregated = (
        combined
        .groupby(
            "original_feature",
            as_index=False,
        )[
            "contribution"
        ]
        .mean()
    )

    aggregated[
        "absolute_contribution"
    ] = (
        aggregated[
            "contribution"
        ].abs()
    )

    aggregated[
        "direction"
    ] = np.where(
        aggregated[
            "contribution"
        ] > 0,
        "increases_model_risk",
        np.where(
            aggregated[
                "contribution"
            ] < 0,
            "decreases_model_risk",
            "neutral",
        ),
    )

    aggregated = (
        aggregated
        .sort_values(
            "absolute_contribution",
            ascending=False,
        )
        .reset_index(
            drop=True
        )
    )

    # --------------------------------------------------------
    # Top contributors
    # --------------------------------------------------------

    positive = (
        aggregated[
            aggregated[
                "contribution"
            ] > 0
        ]
        .head(10)
    )

    negative = (
        aggregated[
            aggregated[
                "contribution"
            ] < 0
        ]
        .sort_values(
            "contribution"
        )
        .head(10)
    )

    result = {

        "model_version":
            "heart-risk-v3",

        "risk_probability":
            round(
                probability,
                6,
            ),

        "risk_percentage":
            round(
                probability * 100,
                2,
            ),

        "explanation_type":
            "aggregated_logistic_model_contributions",

        "important_note":
            (
                "Contributions describe how "
                "the trained model's features "
                "influenced this prediction. "
                "They should not be interpreted "
                "as causal medical effects."
            ),

        "positive_contributors":
            positive[
                [
                    "original_feature",
                    "contribution",
                    "direction",
                ]
            ].to_dict(
                orient="records"
            ),

        "negative_contributors":
            negative[
                [
                    "original_feature",
                    "contribution",
                    "direction",
                ]
            ].to_dict(
                orient="records"
            ),

        "all_feature_contributions":
            aggregated[
                [
                    "original_feature",
                    "contribution",
                    "direction",
                ]
            ].to_dict(
                orient="records"
            ),
    }

    return result


# ============================================================
# EXAMPLE USER
# ============================================================

def create_example_user():

    return {
        "male": 1,
        "age": 55,
        "education": 2,
        "currentSmoker": 0,
        "cigsPerDay": 0,
        "BPMeds": 0,
        "prevalentStroke": 0,
        "prevalentHyp": 1,
        "diabetes": 0,
        "totChol": 220,
        "sysBP": 145,
        "diaBP": 90,
        "BMI": 27.1,
        "heartRate": 75,
        "glucose": 90,
    }


# ============================================================
# MAIN
# ============================================================

def main():

    print("=" * 75)
    print("HEART RISK V3 - EXPLAINABILITY V2")
    print("=" * 75)

    model = load_model()

    # ========================================================
    # GLOBAL
    # ========================================================

    coefficients = (
        extract_coefficients(
            model
        )
    )

    global_importance = (
        aggregate_global_importance(
            coefficients
        )
    )

    global_importance.to_csv(
        EXPLAIN_DIR /
        "grouped_feature_importance.csv",
        index=False,
    )

    coefficients.to_csv(
        EXPLAIN_DIR /
        "raw_model_coefficients.csv",
        index=False,
    )

    print()
    print(
        "Grouped global feature importance:"
    )

    print()

    print(
        global_importance.to_string(
            index=False,
            float_format=lambda x:
                f"{x:.6f}",
        )
    )

    # ========================================================
    # INDIVIDUAL
    # ========================================================

    print()
    print("=" * 75)
    print("EXAMPLE INDIVIDUAL EXPLANATION")
    print("=" * 75)

    user = create_example_user()

    explanation = (
        explain_prediction(
            model,
            user,
        )
    )

    print()

    print(
        f"Risk probability: "
        f"{explanation['risk_percentage']:.2f}%"
    )

    print()
    print(
        "Positive model contributors:"
    )

    for item in (
        explanation[
            "positive_contributors"
        ][:10]
    ):

        print(
            f"  "
            f"{item['original_feature']:20s} "
            f"{item['contribution']:+.5f}"
        )

    print()
    print(
        "Negative model contributors:"
    )

    for item in (
        explanation[
            "negative_contributors"
        ][:10]
    ):

        print(
            f"  "
            f"{item['original_feature']:20s} "
            f"{item['contribution']:+.5f}"
        )

    # ========================================================
    # SAVE JSON
    # ========================================================

    with open(
        EXPLAIN_DIR /
        "individual_explanation_example.json",
        "w",
        encoding="utf-8",
    ) as file:

        json.dump(
            explanation,
            file,
            indent=2,
        )

    print()
    print("=" * 75)
    print("EXPLAINABILITY COMPLETE")
    print("=" * 75)

    print()
    print(
        "Reports:"
    )

    print(
        EXPLAIN_DIR
    )


if __name__ == "__main__":
    main()
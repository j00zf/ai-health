from pathlib import Path

import numpy as np
import pandas as pd


# ============================================================
# PATHS
# ============================================================

ROOT = (
    Path(__file__)
    .resolve()
    .parents[1]
)

DATA_DIR = ROOT / "data"

OUTPUT_FILE = (
    DATA_DIR
    / "pulse_training_dataset.parquet"
)


# ============================================================
# DEPLOYMENT FEATURES
# ============================================================
#
# IMPORTANT:
#
# These are the ONLY features that the production Pulse AI
# models are allowed to consume.
#
# Blood pressure is intentionally excluded because the
# current Pulse AI HealthRecord does not require BP.
#
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

TARGETS = [

    "heart_outcome",

    "health_outcome",

    "wellness_outcome",
]


# ============================================================
# LOAD NHANES XPT
# ============================================================

def load_xpt(filename):

    path = DATA_DIR / filename

    if not path.exists():

        raise FileNotFoundError(
            f"\nMissing dataset:\n"
            f"{path}\n\n"
            f"Run:\n"
            f"python training\\download_data.py"
        )

    print(
        f"Loading {filename}..."
    )

    return pd.read_sas(
        path,
        format="xport"
    )


# ============================================================
# SAFE COLUMN ACCESS
# ============================================================

def get_column(
    df,
    column
):

    if column in df.columns:

        return pd.to_numeric(
            df[column],
            errors="coerce"
        )

    print(
        f"[WARNING] "
        f"'{column}' not found. "
        f"Using NaN."
    )

    return pd.Series(
        np.nan,
        index=df.index
    )


# ============================================================
# MEAN OF AVAILABLE COLUMNS
# ============================================================

def mean_columns(
    df,
    columns
):

    values = []

    for column in columns:

        if column in df.columns:

            values.append(
                get_column(
                    df,
                    column
                )
            )

    if not values:

        return pd.Series(
            np.nan,
            index=df.index
        )

    return pd.concat(
        values,
        axis=1
    ).mean(
        axis=1,
        skipna=True
    )


# ============================================================
# CREATE DATASET
# ============================================================

def create_dataset():

    print(
        "\n"
        "======================================================\n"
        "Loading NHANES datasets...\n"
        "======================================================"
    )

    # --------------------------------------------------------
    # Load datasets
    # --------------------------------------------------------

    demo = load_xpt(
        "P_DEMO.XPT"
    )

    bmx = load_xpt(
        "P_BMX.XPT"
    )

    bpx = load_xpt(
        "P_BPXO.XPT"
    )

    paq = load_xpt(
        "P_PAQ.XPT"
    )

    slq = load_xpt(
        "P_SLQ.XPT"
    )

    smq = load_xpt(
        "P_SMQ.XPT"
    )

    alq = load_xpt(
        "P_ALQ.XPT"
    )

    diq = load_xpt(
        "P_DIQ.XPT"
    )

    mcq = load_xpt(
        "P_MCQ.XPT"
    )

    bpq = load_xpt(
        "P_BPQ.XPT"
    )

    huq = load_xpt(
        "P_HUQ.XPT"
    )


    # ========================================================
    # MERGE
    # ========================================================

    print(
        "\nMerging datasets..."
    )

    datasets = [

        demo,
        bmx,
        bpx,
        paq,
        slq,
        smq,
        alq,
        diq,
        mcq,
        bpq,
        huq,

    ]


    df = datasets[0].copy()


    for dataset in datasets[1:]:

        # Keep SEQN plus only columns not already present.
        columns = [
            "SEQN"
        ] + [
            column
            for column in dataset.columns
            if (
                column != "SEQN"
                and column not in df.columns
            )
        ]


        df = df.merge(
            dataset[
                columns
            ],
            on="SEQN",
            how="left"
        )


    print(
        f"Merged rows: {len(df):,}"
    )


    # ========================================================
    # DEMOGRAPHICS
    # ========================================================

    df["age"] = get_column(
        df,
        "RIDAGEYR"
    )


    df["sex"] = get_column(
        df,
        "RIAGENDR"
    )


    # ========================================================
    # BODY MEASUREMENTS
    # ========================================================

    df["height_cm"] = get_column(
        df,
        "BMXHT"
    )


    df["weight_kg"] = get_column(
        df,
        "BMXWT"
    )


    df["bmi"] = get_column(
        df,
        "BMXBMI"
    )


    df["waist_cm"] = get_column(
        df,
        "BMXWAIST"
    )


    # ========================================================
    # HEART RATE
    # ========================================================
    #
    # NHANES P_BPXO:
    #
    # BPXOPLS1
    # BPXOPLS2
    # BPXOPLS3
    #
    # These are the oscillometric pulse readings.
    #
    # We use them to create the training feature:
    #
    # heart_rate
    #
    # ========================================================

    df["heart_rate"] = mean_columns(
        df,
        [
            "BPXOPLS1",
            "BPXOPLS2",
            "BPXOPLS3",
        ]
    )


    # ========================================================
    # BLOOD PRESSURE
    # ========================================================
    #
    # BP is deliberately NOT used as a model feature.
    #
    # We do NOT create systolic_bp or diastolic_bp in the
    # final deployment dataset.
    #
    # This keeps training compatible with Pulse AI.
    #
    # ========================================================


    # ========================================================
    # PHYSICAL ACTIVITY
    # ========================================================
    #
    # Approximate weekly activity measure:
    #
    # vigorous days × vigorous minutes
    # +
    # moderate days × moderate minutes
    # +
    # walking days × walking minutes
    #
    # ========================================================

    vigorous_days = get_column(
        df,
        "PAQ655"
    )


    vigorous_minutes = get_column(
        df,
        "PAD645"
    )


    moderate_days = get_column(
        df,
        "PAQ670"
    )


    moderate_minutes = get_column(
        df,
        "PAD675"
    )


    walking_days = get_column(
        df,
        "PAQ610"
    )


    walking_minutes = get_column(
        df,
        "PAD615"
    )


    vigorous_activity = (
        vigorous_days.fillna(0)
        *
        vigorous_minutes.fillna(0)
    )


    moderate_activity = (
        moderate_days.fillna(0)
        *
        moderate_minutes.fillna(0)
    )


    walking_activity = (
        walking_days.fillna(0)
        *
        walking_minutes.fillna(0)
    )


    df["activity_minutes"] = (
        vigorous_activity
        +
        moderate_activity
        +
        walking_activity
    )


    # ========================================================
    # SLEEP
    # ========================================================

    weekday_sleep = get_column(
        df,
        "SLD012"
    )


    weekend_sleep = get_column(
        df,
        "SLD013"
    )


    df["sleep_hours"] = (
        weekday_sleep
        .fillna(
            weekend_sleep
        )
    )


    # ========================================================
    # SMOKING
    # ========================================================

    smoking = get_column(
        df,
        "SMQ020"
    )


    df["smoking"] = np.where(

        smoking == 1,

        1,

        np.where(
            smoking == 2,
            0,
            np.nan
        )
    )


    # ========================================================
    # ALCOHOL
    # ========================================================

    alcohol = get_column(
        df,
        "ALQ111"
    )


    df["alcohol"] = np.where(

        alcohol == 1,

        1,

        np.where(
            alcohol == 2,
            0,
            np.nan
        )
    )


    # ========================================================
    # HEART TARGET
    # ========================================================
    #
    # Research target based on reported:
    #
    # - Heart failure
    # - Coronary heart disease
    # - Heart attack
    # - Stroke
    #
    # This is NOT a medical diagnosis.
    #
    # ========================================================

    heart_failure = (
        get_column(
            df,
            "MCQ160B"
        )
        == 1
    )


    coronary_disease = (
        get_column(
            df,
            "MCQ160C"
        )
        == 1
    )


    heart_attack = (
        get_column(
            df,
            "MCQ160E"
        )
        == 1
    )


    stroke = (
        get_column(
            df,
            "MCQ160F"
        )
        == 1
    )


    df["heart_outcome"] = (

        heart_failure
        |
        coronary_disease
        |
        heart_attack
        |
        stroke

    ).astype(int)


    # ========================================================
    # HEALTH TARGET
    # ========================================================
    #
    # Includes:
    #
    # - Diabetes
    # - Hypertension diagnosis
    # - Cardiovascular conditions
    #
    # Research target only.
    #
    # ========================================================

    diabetes = (
        get_column(
            df,
            "DIQ010"
        )
        == 1
    )


    hypertension = (
        get_column(
            df,
            "BPQ020"
        )
        == 1
    )


    df["health_outcome"] = (

        diabetes
        |
        hypertension
        |
        heart_failure
        |
        coronary_disease
        |
        heart_attack
        |
        stroke

    ).astype(int)


    # ========================================================
    # WELLNESS TARGET
    # ========================================================
    #
    # HUQ010:
    #
    # 1 = Excellent
    # 2 = Very good
    # 3 = Good
    # 4 = Fair
    # 5 = Poor
    #
    # We create a binary wellness target:
    #
    # 1 = Excellent / Very good / Good
    # 0 = Fair / Poor
    #
    # This is a self-rated-health proxy.
    #
    # ========================================================

    general_health = get_column(
        df,
        "HUQ010"
    )


    df["wellness_outcome"] = np.where(

        general_health.isin(
            [1, 2, 3]
        ),

        1,

        np.where(
            general_health.isin(
                [4, 5]
            ),
            0,
            np.nan
        )
    )


    # ========================================================
    # SELECT DEPLOYMENT DATASET
    # ========================================================
    #
    # IMPORTANT:
    #
    # Only FEATURES + TARGETS are retained.
    #
    # BP cannot accidentally enter the model.
    #
    # ========================================================

    final_columns = (
        FEATURES
        +
        TARGETS
    )


    df = df[
        final_columns
    ].copy()


    # ========================================================
    # CLEAN VALUES
    # ========================================================

    # Age

    df.loc[
        ~df["age"].between(
            18,
            100
        ),
        "age"
    ] = np.nan


    # Height

    df.loc[
        ~df["height_cm"].between(
            100,
            230
        ),
        "height_cm"
    ] = np.nan


    # Weight

    df.loc[
        ~df["weight_kg"].between(
            30,
            250
        ),
        "weight_kg"
    ] = np.nan


    # BMI

    df.loc[
        ~df["bmi"].between(
            10,
            70
        ),
        "bmi"
    ] = np.nan


    # Waist

    df.loc[
        ~df["waist_cm"].between(
            40,
            200
        ),
        "waist_cm"
    ] = np.nan


    # Heart rate

    df.loc[
        ~df["heart_rate"].between(
            30,
            220
        ),
        "heart_rate"
    ] = np.nan


    # Sleep

    df.loc[
        ~df["sleep_hours"].between(
            0,
            24
        ),
        "sleep_hours"
    ] = np.nan


    # Activity

    df.loc[
        df["activity_minutes"] < 0,
        "activity_minutes"
    ] = np.nan


    # ========================================================
    # SAVE
    # ========================================================

    OUTPUT_FILE.parent.mkdir(
        parents=True,
        exist_ok=True
    )


    df.to_parquet(
        OUTPUT_FILE,
        index=False
    )


    # ========================================================
    # REPORT
    # ========================================================

    print(
        "\n"
        + "=" * 70
    )

    print(
        "PULSE AI DEPLOYMENT TRAINING DATASET"
    )

    print(
        "=" * 70
    )


    print(
        f"\nRows: {len(df):,}"
    )


    print(
        f"Columns: {len(df.columns)}"
    )


    print(
        "\nDeployment features:"
    )


    for feature in FEATURES:

        print(
            f"  ✓ {feature}"
        )


    print(
        "\nExcluded from production model:"
    )


    print(
        "  ✗ systolic_bp"
    )


    print(
        "  ✗ diastolic_bp"
    )


    print(
        "\nTargets:"
    )


    for target in TARGETS:

        print(
            f"\n{target}:"
        )

        print(
            df[target]
            .value_counts(
                dropna=False
            )
        )


    print(
        "\nMissing values:"
    )


    print(
        df.isna()
        .sum()
        .sort_values(
            ascending=False
        )
    )


    print(
        "\nFinal columns:"
    )


    print(
        df.columns.tolist()
    )


    print(
        "\nSaved:"
    )


    print(
        OUTPUT_FILE
    )


    print(
        "\nDataset preparation complete."
    )


# ============================================================
# ENTRY POINT
# ============================================================

if __name__ == "__main__":

    create_dataset()
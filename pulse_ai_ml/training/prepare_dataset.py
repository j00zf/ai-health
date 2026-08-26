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


DATA_DIR = (
    ROOT / "data"
)


OUTPUT_FILE = (
    DATA_DIR
    / "pulse_training_dataset.parquet"
)


# ============================================================
# LOAD XPT
# ============================================================

def load_xpt(filename):

    path = (
        DATA_DIR / filename
    )


    if not path.exists():

        raise FileNotFoundError(
            f"\nMissing dataset:\n{path}\n\n"
            "Run:\n"
            "python training\\download_data.py"
        )


    print(
        f"Loading {filename}..."
    )


    return pd.read_sas(
        path,
        format="xport"
    )


# ============================================================
# SAFE COLUMN
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

    # ========================================================
    # LOAD
    # ========================================================

    print(
        "\nLoading NHANES datasets...\n"
    )


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

        # Only keep SEQN + unique columns
        columns = [
            "SEQN"
        ] + [
            column
            for column in dataset.columns
            if column != "SEQN"
            and column not in df.columns
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
    # BODY
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
    # P_BPXO uses:
    #
    # BPXOPLS1
    # BPXOPLS2
    # BPXOPLS3
    #
    # CDC identifies these as oscillometric pulse readings.
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

    df["systolic_bp"] = mean_columns(
        df,
        [
            "BPXOSY1",
            "BPXOSY2",
            "BPXOSY3",
        ]
    )


    df["diastolic_bp"] = mean_columns(
        df,
        [
            "BPXODI1",
            "BPXODI2",
            "BPXODI3",
        ]
    )


    # ========================================================
    # PHYSICAL ACTIVITY
    # ========================================================
    #
    # Create a normalized activity measure:
    #
    # activity_minutes
    #
    # This replaces the old activity_days variable.
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
        vigorous_days
        .fillna(0)
        *
        vigorous_minutes
        .fillna(0)
    )


    moderate_activity = (
        moderate_days
        .fillna(0)
        *
        moderate_minutes
        .fillna(0)
    )


    walking_activity = (
        walking_days
        .fillna(0)
        *
        walking_minutes
        .fillna(0)
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
        .fillna(weekend_sleep)
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
    # Existing diagnosed cardiovascular conditions.
    #
    # 1 = condition present
    # 0 = none of the selected conditions reported
    #
    # This is a research target, not a diagnosis.
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
    # Cardiometabolic health outcome.
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
    # self-rated general health.
    #
    # 1 = excellent
    # 2 = very good
    # 3 = good
    # 4 = fair
    # 5 = poor
    #
    # We create:
    #
    # wellness_outcome = 1
    # when general health is excellent/very good/good.
    #
    # wellness_outcome = 0
    # when fair/poor.
    #
    # This is a wellbeing proxy, not a clinical diagnosis.
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
    # FEATURES
    # ========================================================

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


    TARGETS = [

        "heart_outcome",

        "health_outcome",

        "wellness_outcome",
    ]


    # ========================================================
    # FINAL DATASET
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

    df.loc[
        ~df["age"].between(
            18,
            100
        ),
        "age"
    ] = np.nan


    df.loc[
        ~df["height_cm"].between(
            100,
            230
        ),
        "height_cm"
    ] = np.nan


    df.loc[
        ~df["weight_kg"].between(
            30,
            250
        ),
        "weight_kg"
    ] = np.nan


    df.loc[
        ~df["bmi"].between(
            10,
            70
        ),
        "bmi"
    ] = np.nan


    df.loc[
        ~df["waist_cm"].between(
            40,
            200
        ),
        "waist_cm"
    ] = np.nan


    df.loc[
        ~df["heart_rate"].between(
            30,
            220
        ),
        "heart_rate"
    ] = np.nan


    df.loc[
        ~df["systolic_bp"].between(
            60,
            300
        ),
        "systolic_bp"
    ] = np.nan


    df.loc[
        ~df["diastolic_bp"].between(
            30,
            200
        ),
        "diastolic_bp"
    ] = np.nan


    df.loc[
        ~df["sleep_hours"].between(
            0,
            24
        ),
        "sleep_hours"
    ] = np.nan


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
        "PULSE AI TRAINING DATASET"
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
        "\nFeatures:"
    )


    for feature in FEATURES:

        print(
            f"  ✓ {feature}"
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
        "\nSaved:"
    )


    print(
        OUTPUT_FILE
    )


if __name__ == "__main__":

    create_dataset()
from pathlib import Path

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

from .config import DATA_PATH, TARGET


REPORT_DIR = Path(__file__).resolve().parents[1] / "reports"
PLOT_DIR = REPORT_DIR / "eda_plots"


def main():
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    PLOT_DIR.mkdir(parents=True, exist_ok=True)

    print("=" * 70)
    print("HEART RISK MODEL - DATASET EDA")
    print("=" * 70)

    df = pd.read_csv(DATA_PATH)

    print("\n1. DATASET SHAPE")
    print("-" * 70)
    print(f"Rows    : {df.shape[0]}")
    print(f"Columns : {df.shape[1]}")

    print("\n2. COLUMNS")
    print("-" * 70)
    for column in df.columns:
        print(column)

    print("\n3. DATA TYPES")
    print("-" * 70)
    print(df.dtypes)

    print("\n4. MISSING VALUES")
    print("-" * 70)

    missing = df.isnull().sum()
    missing_percentage = (missing / len(df)) * 100

    missing_report = pd.DataFrame({
        "missing_count": missing,
        "missing_percentage": missing_percentage
    })

    missing_report = missing_report.sort_values(
        "missing_percentage",
        ascending=False
    )

    print(missing_report)

    missing_report.to_csv(
        REPORT_DIR / "missing_values.csv"
    )

    print("\n5. DUPLICATES")
    print("-" * 70)

    duplicate_count = df.duplicated().sum()

    print(f"Duplicate rows: {duplicate_count}")

    print("\n6. TARGET DISTRIBUTION")
    print("-" * 70)

    target_counts = df[TARGET].value_counts()
    target_percentages = df[TARGET].value_counts(normalize=True) * 100

    target_report = pd.DataFrame({
        "count": target_counts,
        "percentage": target_percentages
    })

    print(target_report)

    target_report.to_csv(
        REPORT_DIR / "target_distribution.csv"
    )

    # Target plot
    plt.figure(figsize=(7, 5))

    sns.countplot(
        data=df,
        x=TARGET
    )

    plt.title("Ten-Year CHD Outcome Distribution")
    plt.xlabel("TenYearCHD")
    plt.ylabel("Number of Patients")

    plt.tight_layout()

    plt.savefig(
        PLOT_DIR / "target_distribution.png",
        dpi=150
    )

    plt.close()

    print("\n7. NUMERICAL SUMMARY")
    print("-" * 70)

    numerical = df.select_dtypes(
        include=["int64", "float64"]
    )

    summary = numerical.describe().T

    summary.to_csv(
        REPORT_DIR / "numerical_summary.csv"
    )

    print(summary)

    print("\n8. UNIQUE VALUES")
    print("-" * 70)

    for column in df.columns:
        print(
            f"{column:25s}: "
            f"{df[column].nunique()} unique values"
        )

    print("\n9. CORRELATION WITH TARGET")
    print("-" * 70)

    correlation = numerical.corr()[TARGET].sort_values(
        ascending=False
    )

    print(correlation)

    correlation.to_csv(
        REPORT_DIR / "target_correlations.csv"
    )

    # Correlation heatmap
    plt.figure(figsize=(13, 10))

    sns.heatmap(
        numerical.corr(),
        annot=True,
        fmt=".2f",
        cmap="coolwarm",
        center=0
    )

    plt.title("Feature Correlation Matrix")

    plt.tight_layout()

    plt.savefig(
        PLOT_DIR / "correlation_heatmap.png",
        dpi=150
    )

    plt.close()

    print("\n10. NUMERICAL FEATURE DISTRIBUTIONS")
    print("-" * 70)

    for column in numerical.columns:

        plt.figure(figsize=(7, 5))

        sns.histplot(
            data=df,
            x=column,
            kde=True
        )

        plt.title(f"Distribution: {column}")

        plt.tight_layout()

        filename = (
            column.lower()
            .replace(" ", "_")
            + "_distribution.png"
        )

        plt.savefig(
            PLOT_DIR / filename,
            dpi=150
        )

        plt.close()

    print("\n11. FEATURE DISTRIBUTIONS BY TARGET")
    print("-" * 70)

    for column in numerical.columns:

        if column == TARGET:
            continue

        plt.figure(figsize=(7, 5))

        sns.boxplot(
            data=df,
            x=TARGET,
            y=column
        )

        plt.title(
            f"{column} vs Ten-Year CHD Outcome"
        )

        plt.tight_layout()

        filename = (
            column.lower()
            + "_vs_target.png"
        )

        plt.savefig(
            PLOT_DIR / filename,
            dpi=150
        )

        plt.close()

    print("\nEDA completed successfully.")

    print("\nReports saved to:")
    print(REPORT_DIR)

    print("\nPlots saved to:")
    print(PLOT_DIR)


if __name__ == "__main__":
    main()
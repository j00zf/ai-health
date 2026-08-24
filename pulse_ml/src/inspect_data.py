import pandas as pd


DATASET = "../data/raw/cardio_train.csv"


def main():

    df = pd.read_csv(
        DATASET,
        sep=";"
    )

    print("=" * 70)
    print("PULSE AI — DATASET INSPECTION")
    print("=" * 70)

    print("\nShape:")
    print(df.shape)

    print("\nColumns:")
    print(
        df.columns.tolist()
    )

    print("\nData types:")
    print(
        df.dtypes
    )

    print("\nMissing values:")
    print(
        df.isnull().sum()
    )

    print("\nDuplicates:")
    print(
        df.duplicated().sum()
    )

    print("\nFirst five rows:")
    print(
        df.head()
    )

    print("\nTarget distribution:")
    print(
        df["cardio"]
        .value_counts()
    )

    print("\nTarget percentages:")
    print(
        df["cardio"]
        .value_counts(
            normalize=True
        ) * 100
    )

    print("\nNumerical summary:")
    print(
        df.describe().T
    )


if __name__ == "__main__":
    main()
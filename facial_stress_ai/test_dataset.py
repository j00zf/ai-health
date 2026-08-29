from src.dataset import (
    FacialStressDataset,
    load_cleaned_dataframe,
    TRAIN_TRANSFORM
)


def main():

    # Load cleaned CSV
    df = load_cleaned_dataframe()

    print("=" * 60)
    print("DATASET LOADER TEST")
    print("=" * 60)

    print(f"\nTotal samples: {len(df)}")

    print("\nClass distribution:")

    print(
        df["emotion"]
        .value_counts()
        .sort_index()
    )


    # Create dataset
    dataset = FacialStressDataset(

        dataframe=df,

        transform=TRAIN_TRANSFORM

    )


    # Get one sample
    image, label = dataset[0]


    print("\nSample image shape:")

    print(image.shape)


    print("\nSample image dtype:")

    print(image.dtype)


    print("\nSample label:")

    print(label.item())


    print("\nImage value range:")

    print(
        image.min().item(),
        "to",
        image.max().item()
    )


    # Test another sample
    image2, label2 = dataset[10]

    print("\nSecond sample shape:")

    print(image2.shape)

    print("\nSecond label:")

    print(label2.item())


    print("\n" + "=" * 60)
    print("DATASET TEST SUCCESSFUL")
    print("=" * 60)


if __name__ == "__main__":

    main()
import os
import matplotlib.pyplot as plt

from src.dataset import FacialStressDataset, load_cleaned_dataframe
from src.augmentations import TRAIN_TRANSFORM, EVAL_TRANSFORM


def main():

    print("=" * 70)
    print("DATA AUGMENTATION TEST")
    print("=" * 70)

    print("\nLoading dataset...")

    df = load_cleaned_dataframe()

    print(f"Total samples: {len(df)}")

    train_dataset = FacialStressDataset(
        dataframe=df,
        transform=TRAIN_TRANSFORM
    )

    eval_dataset = FacialStressDataset(
        dataframe=df,
        transform=EVAL_TRANSFORM
    )

    sample_index = 0

    print(f"\nTesting sample index: {sample_index}")

    augmented_images = []

    for i in range(5):

        image, label = train_dataset[sample_index]

        augmented_images.append(
            image.squeeze(0).cpu().numpy()
        )

        print(
            f"Generated augmented image {i + 1}"
        )

    original_image, original_label = eval_dataset[
        sample_index
    ]

    original_image = (
        original_image
        .squeeze(0)
        .cpu()
        .numpy()
    )

    print(f"\nLabel: {label}")

    fig, axes = plt.subplots(
        1,
        6,
        figsize=(15, 4)
    )

    axes[0].imshow(
        original_image,
        cmap="gray"
    )

    axes[0].set_title("Original")
    axes[0].axis("off")

    for i, image in enumerate(augmented_images):

        axes[i + 1].imshow(
            image,
            cmap="gray"
        )

        axes[i + 1].set_title(
            f"Augmented {i + 1}"
        )

        axes[i + 1].axis("off")

    plt.tight_layout()

    output_dir = "data/processed"

    os.makedirs(
        output_dir,
        exist_ok=True
    )

    output_path = os.path.join(
        output_dir,
        "augmentation_test.png"
    )

    plt.savefig(
        output_path,
        dpi=150
    )

    plt.close()

    print("\nAugmentation test image saved:")
    print(output_path)

    print("\n" + "=" * 70)
    print("AUGMENTATION TEST SUCCESSFUL")
    print("=" * 70)


if __name__ == "__main__":
    main()
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt

from src.dataset import load_cleaned_dataframe


# ============================================================
# OUTPUT DIRECTORY
# ============================================================

OUTPUT_DIR = Path(
    "data/processed/label_samples"
)


# ============================================================
# CONVERT PIXELS TO IMAGE
# ============================================================

def pixels_to_image(pixel_string):

    pixels = np.array(

        list(
            map(
                float,
                pixel_string.split()
            )
        ),

        dtype=np.float32

    )


    image = pixels.reshape(
        48,
        48
    )


    return image


# ============================================================
# MAIN
# ============================================================

def main():

    print("=" * 70)

    print(
        "FACIAL DATA LABEL INSPECTION"
    )

    print("=" * 70)


    # --------------------------------------------------------
    # LOAD DATA
    # --------------------------------------------------------

    df = load_cleaned_dataframe()


    print(
        f"\nTotal samples: {len(df)}"
    )


    # --------------------------------------------------------
    # LABEL COUNTS
    # --------------------------------------------------------

    print(
        "\nLABEL DISTRIBUTION:"
    )


    label_counts = df[
        "emotion"
    ].value_counts().sort_index()


    print(
        label_counts
    )


    # --------------------------------------------------------
    # CREATE OUTPUT DIRECTORY
    # --------------------------------------------------------

    OUTPUT_DIR.mkdir(

        parents=True,

        exist_ok=True

    )


    # --------------------------------------------------------
    # SAVE EXAMPLE IMAGES
    # --------------------------------------------------------

    print(
        "\nSaving sample images..."
    )


    for label in sorted(
        df["emotion"].unique()
    ):


        label_data = df[
            df["emotion"] == label
        ]


        # Save up to 10 examples
        sample_count = min(
            10,
            len(label_data)
        )


        for index in range(
            sample_count
        ):


            row = label_data.iloc[
                index
            ]


            image = pixels_to_image(

                row[
                    "pixels"
                ]

            )


            output_path = (

                OUTPUT_DIR

                /

                f"class_{label}_sample_{index + 1}.png"

            )


            plt.imsave(

                output_path,

                image,

                cmap="gray"

            )


        print(

            f"Class {label}: "
            f"saved {sample_count} images"

        )


    # --------------------------------------------------------
    # CREATE VISUAL GRID
    # --------------------------------------------------------

    labels = sorted(
        df["emotion"].unique()
    )


    fig, axes = plt.subplots(

        len(labels),

        5,

        figsize=(12, 5)

    )


    if len(labels) == 1:

        axes = [axes]


    for row_index, label in enumerate(
        labels
    ):


        samples = df[
            df["emotion"] == label
        ].head(5)


        for column_index, (

            _,
            row

        ) in enumerate(

            samples.iterrows()

        ):


            image = pixels_to_image(

                row[
                    "pixels"
                ]

            )


            ax = axes[
                row_index,
                column_index
            ]


            ax.imshow(

                image,

                cmap="gray"

            )


            ax.set_title(

                f"Class {label}"

            )


            ax.axis(
                "off"
            )


    plt.tight_layout()


    grid_path = (

        OUTPUT_DIR

        /

        "label_comparison.png"

    )


    plt.savefig(

        grid_path,

        dpi=150

    )


    plt.close()


    print(

        f"\nComparison image saved:"

    )

    print(
        grid_path
    )


    print("\n" + "=" * 70)

    print(
        "LABEL INSPECTION COMPLETE"
    )

    print("=" * 70)


if __name__ == "__main__":

    main()
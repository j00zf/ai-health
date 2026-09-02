import json
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


# ============================================================
# PATHS
# ============================================================

OUTPUT_DIR = Path(
    "outputs"
)

VISUALIZATION_DIR = (
    OUTPUT_DIR
    /
    "visualizations"
)


V1_RESULTS_FILE = (
    OUTPUT_DIR
    /
    "v1_results.json"
)


V2_RESULTS_FILE = (
    OUTPUT_DIR
    /
    "v2_results.json"
)


# ============================================================
# LOAD JSON
# ============================================================

def load_json(path):

    if not path.exists():

        raise FileNotFoundError(
            f"File not found:\n{path}"
        )


    with open(
        path,
        "r",
        encoding="utf-8"
    ) as file:

        return json.load(
            file
        )


# ============================================================
# NORMALIZE RESULTS
# ============================================================

def normalize_results(data):

    # --------------------------------------------------------
    # V1 FORMAT
    # --------------------------------------------------------

    if "class_metrics" in data:

        return {

            "model_version":

                data.get(
                    "model_version",
                    "V1"
                ),


            "test_accuracy":

                data.get(
                    "test_accuracy"
                ),


            "class_0_f1":

                data[
                    "class_metrics"
                ][
                    "class_0"
                ][
                    "f1_score"
                ],


            "class_1_f1":

                data[
                    "class_metrics"
                ][
                    "class_1"
                ][
                    "f1_score"
                ],


            "confusion_matrix":

                data.get(
                    "confusion_matrix"
                )

        }


    # --------------------------------------------------------
    # V2 FORMAT
    # --------------------------------------------------------

    return {

        "model_version":

            data.get(
                "model_version",
                "V2"
            ),


        "test_accuracy":

            data.get(
                "test_accuracy"
            ),


        "class_0_f1":

            data[
                "class_0"
            ][
                "f1"
            ],


        "class_1_f1":

            data[
                "class_1"
            ][
                "f1"
            ],


        "confusion_matrix":

            data.get(
                "confusion_matrix"
            )

    }


# ============================================================
# SAVE CONFUSION MATRIX
# ============================================================

def plot_confusion_matrix(
    matrix,
    model_name,
    output_path
):

    matrix = np.array(
        matrix
    )


    fig, ax = plt.subplots(
        figsize=(7, 6)
    )


    image = ax.imshow(
        matrix
    )


    plt.colorbar(
        image,
        ax=ax
    )


    ax.set_xticks(
        [0, 1]
    )

    ax.set_yticks(
        [0, 1]
    )


    ax.set_xticklabels(
        ["Non-Stress", "Stress"]
    )

    ax.set_yticklabels(
        ["Non-Stress", "Stress"]
    )


    ax.set_xlabel(
        "Predicted Class"
    )

    ax.set_ylabel(
        "Actual Class"
    )


    ax.set_title(
        f"{model_name} Confusion Matrix"
    )


    for row in range(
        matrix.shape[0]
    ):

        for column in range(
            matrix.shape[1]
        ):

            ax.text(

                column,

                row,

                str(
                    matrix[
                        row,
                        column
                    ]
                ),

                ha="center",

                va="center"

            )


    plt.tight_layout()


    plt.savefig(
        output_path,
        dpi=300
    )


    plt.close()


# ============================================================
# ACCURACY COMPARISON
# ============================================================

def plot_accuracy_comparison(
    v1,
    v2,
    output_path
):

    models = [

        v1[
            "model_version"
        ],

        v2[
            "model_version"
        ]

    ]


    accuracies = [

        v1[
            "test_accuracy"
        ] * 100,

        v2[
            "test_accuracy"
        ] * 100

    ]


    plt.figure(
        figsize=(8, 6)
    )


    bars = plt.bar(

        models,

        accuracies

    )


    plt.title(
        "Model Accuracy Comparison"
    )


    plt.ylabel(
        "Accuracy (%)"
    )


    plt.ylim(
        0,
        100
    )


    for bar, accuracy in zip(
        bars,
        accuracies
    ):

        plt.text(

            bar.get_x()
            +
            bar.get_width()
            /
            2,

            bar.get_height()
            +
            2,

            f"{accuracy:.2f}%",

            ha="center"

        )


    plt.tight_layout()


    plt.savefig(
        output_path,
        dpi=300
    )


    plt.close()


# ============================================================
# F1 SCORE COMPARISON
# ============================================================

def plot_f1_comparison(
    v1,
    v2,
    output_path
):

    classes = [

        "Non-Stress",

        "Stress"

    ]


    v1_scores = [

        v1[
            "class_0_f1"
        ] * 100,

        v1[
            "class_1_f1"
        ] * 100

    ]


    v2_scores = [

        v2[
            "class_0_f1"
        ] * 100,

        v2[
            "class_1_f1"
        ] * 100

    ]


    x = np.arange(
        len(
            classes
        )
    )


    width = 0.35


    plt.figure(
        figsize=(9, 6)
    )


    plt.bar(

        x - width / 2,

        v1_scores,

        width,

        label="V1"

    )


    plt.bar(

        x + width / 2,

        v2_scores,

        width,

        label="V2"

    )


    plt.xticks(

        x,

        classes

    )


    plt.ylabel(
        "F1 Score (%)"
    )


    plt.title(
        "Class-wise F1 Score Comparison"
    )


    plt.ylim(
        0,
        100
    )


    plt.legend()


    plt.tight_layout()


    plt.savefig(
        output_path,
        dpi=300
    )


    plt.close()


# ============================================================
# COMBINED COMPARISON
# ============================================================

def plot_combined_comparison(
    v1,
    v2,
    output_path
):

    metrics = [

        "Accuracy",

        "Non-Stress F1",

        "Stress F1"

    ]


    v1_values = [

        v1[
            "test_accuracy"
        ] * 100,

        v1[
            "class_0_f1"
        ] * 100,

        v1[
            "class_1_f1"
        ] * 100

    ]


    v2_values = [

        v2[
            "test_accuracy"
        ] * 100,

        v2[
            "class_0_f1"
        ] * 100,

        v2[
            "class_1_f1"
        ] * 100

    ]


    x = np.arange(
        len(
            metrics
        )
    )


    width = 0.35


    plt.figure(
        figsize=(10, 6)
    )


    plt.bar(

        x - width / 2,

        v1_values,

        width,

        label="V1"

    )


    plt.bar(

        x + width / 2,

        v2_values,

        width,

        label="V2"

    )


    plt.xticks(

        x,

        metrics

    )


    plt.ylabel(
        "Score (%)"
    )


    plt.title(
        "Facial Stress Model Performance Comparison"
    )


    plt.ylim(
        0,
        100
    )


    plt.legend()


    plt.tight_layout()


    plt.savefig(
        output_path,
        dpi=300
    )


    plt.close()


# ============================================================
# MAIN
# ============================================================

def main():

    print("=" * 70)

    print(
        "FACIAL STRESS MODEL VISUALIZATION"
    )

    print("=" * 70)


    # --------------------------------------------------------
    # CREATE OUTPUT DIRECTORY
    # --------------------------------------------------------

    VISUALIZATION_DIR.mkdir(

        parents=True,

        exist_ok=True

    )


    # --------------------------------------------------------
    # LOAD RESULTS
    # --------------------------------------------------------

    print(
        "\nLoading model results..."
    )


    v1_raw = load_json(
        V1_RESULTS_FILE
    )


    v2_raw = load_json(
        V2_RESULTS_FILE
    )


    # --------------------------------------------------------
    # NORMALIZE RESULTS
    # --------------------------------------------------------

    v1 = normalize_results(
        v1_raw
    )


    v2 = normalize_results(
        v2_raw
    )


    # --------------------------------------------------------
    # V1 CONFUSION MATRIX
    # --------------------------------------------------------

    print(
        "\nGenerating V1 confusion matrix..."
    )


    plot_confusion_matrix(

        v1[
            "confusion_matrix"
        ],

        "V1",

        VISUALIZATION_DIR
        /
        "v1_confusion_matrix.png"

    )


    # --------------------------------------------------------
    # V2 CONFUSION MATRIX
    # --------------------------------------------------------

    print(
        "Generating V2 confusion matrix..."
    )


    plot_confusion_matrix(

        v2[
            "confusion_matrix"
        ],

        "V2",

        VISUALIZATION_DIR
        /
        "v2_confusion_matrix.png"

    )


    # --------------------------------------------------------
    # ACCURACY COMPARISON
    # --------------------------------------------------------

    print(
        "Generating accuracy comparison..."
    )


    plot_accuracy_comparison(

        v1,

        v2,

        VISUALIZATION_DIR
        /
        "accuracy_comparison.png"

    )


    # --------------------------------------------------------
    # F1 COMPARISON
    # --------------------------------------------------------

    print(
        "Generating F1 comparison..."
    )


    plot_f1_comparison(

        v1,

        v2,

        VISUALIZATION_DIR
        /
        "f1_comparison.png"

    )


    # --------------------------------------------------------
    # COMBINED COMPARISON
    # --------------------------------------------------------

    print(
        "Generating combined comparison..."
    )


    plot_combined_comparison(

        v1,

        v2,

        VISUALIZATION_DIR
        /
        "model_comparison.png"

    )


    # --------------------------------------------------------
    # COMPLETE
    # --------------------------------------------------------

    print(
        "\n" + "=" * 70
    )

    print(
        "VISUALIZATION COMPLETE"
    )

    print(
        "=" * 70
    )


    print(
        "\nGenerated files:"
    )


    for file_path in sorted(
        VISUALIZATION_DIR.glob(
            "*.png"
        )
    ):

        print(
            f"  {file_path}"
        )


# ============================================================
# RUN
# ============================================================

if __name__ == "__main__":

    main()
import os
import joblib


MODEL_PATH = "../models/advanced/xgboost.pkl"

OUTPUT_PATH = (
    "../models/advanced/"
    "pulse_ai_advanced_v1.json"
)


def main():

    print("=" * 70)
    print(
        "PULSE AI — EXPORT ADVANCED MODEL"
    )
    print("=" * 70)

    print(
        "\nLoading trained XGBoost model..."
    )

    model = joblib.load(
        MODEL_PATH
    )

    print(
        f"Model type: {type(model)}"
    )

    if not hasattr(
        model,
        "get_booster",
    ):
        raise RuntimeError(
            "The loaded model is not "
            "an XGBoost model."
        )

    booster = model.get_booster()

    print(
        "\nExporting Booster..."
    )

    booster.save_model(
        OUTPUT_PATH
    )

    print(
        "\nModel exported successfully:"
    )

    print(
        os.path.abspath(
            OUTPUT_PATH
        )
    )


if __name__ == "__main__":
    main()
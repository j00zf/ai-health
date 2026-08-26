from predictor import get_predictor


def main():

    predictor = get_predictor()


    sample_user = {

        "age":
            25,

        "sex":
            1,

        "height_cm":
            175,

        "weight_kg":
            70,

        "bmi":
            22.86,

        "waist_cm":
            80,

        "heart_rate":
            72,

        "activity_minutes":
            180,

        "sleep_hours":
            7.5,

        "smoking":
            0,

        "alcohol":
            0,
    }


    result = predictor.predict(
        sample_user
    )


    print(
        "\n"
        + "=" * 60
    )

    print(
        "PULSE AI ML PREDICTION"
    )

    print(
        "=" * 60
    )


    print(
        "\n❤️ Heart:"
    )

    print(
        result["heart"]
    )


    print(
        "\n🏥 Health:"
    )

    print(
        result["health"]
    )


    print(
        "\n🌿 Wellness:"
    )

    print(
        result["wellness"]
    )


if __name__ == "__main__":

    main()
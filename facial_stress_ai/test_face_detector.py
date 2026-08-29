from src.face_detector import (
    detect_face,
    save_face_crop
)


def main():

    image_path = (
        "data/test_images/test_face.jpg"
    )


    print("=" * 60)

    print("FACE DETECTION TEST")

    print("=" * 60)


    result = detect_face(
        image_path
    )


    if result is None:

        print(
            "\nNo face detected."
        )

        return


    print(
        f"\nFaces detected: "
        f"{result['faces_detected']}"
    )


    print(
        "\nSelected face:"
    )

    print(
        result["bounding_box"]
    )


    output_path = save_face_crop(

        result["face_image"],

        "data/processed/detected_face.jpg"

    )


    print(
        f"\nFace crop saved to:"
    )

    print(
        output_path
    )


    print("\n" + "=" * 60)

    print(
        "FACE DETECTION SUCCESSFUL"
    )

    print("=" * 60)


if __name__ == "__main__":

    main()
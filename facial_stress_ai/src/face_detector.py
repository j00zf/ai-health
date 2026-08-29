from pathlib import Path

import cv2


# ==========================================
# HAAR CASCADE PATH
# ==========================================

CASCADE_PATH = (
    Path(cv2.data.haarcascades)
    / "haarcascade_frontalface_default.xml"
)


# ==========================================
# LOAD FACE DETECTOR
# ==========================================

face_detector = cv2.CascadeClassifier(
    str(CASCADE_PATH)
)


# ==========================================
# DETECT FACE
# ==========================================

def detect_face(image_path):

    image_path = Path(image_path)

    if not image_path.exists():

        raise FileNotFoundError(
            f"Image not found:\n{image_path}"
        )


    # Load image
    image = cv2.imread(
        str(image_path)
    )


    if image is None:

        raise ValueError(
            "Unable to read image"
        )


    # Convert to grayscale
    gray = cv2.cvtColor(
        image,
        cv2.COLOR_BGR2GRAY
    )


    # Detect faces
    faces = face_detector.detectMultiScale(

        gray,

        scaleFactor=1.1,

        minNeighbors=5,

        minSize=(40, 40)

    )


    # No face found
    if len(faces) == 0:

        return None


    # Select largest face
    largest_face = max(

        faces,

        key=lambda face:
            face[2] * face[3]

    )


    x, y, width, height = largest_face


    # Crop face
    face_image = image[
        y:y + height,
        x:x + width
    ]


    return {

        "face_image": face_image,

        "bounding_box": {

            "x": int(x),
            "y": int(y),
            "width": int(width),
            "height": int(height)

        },

        "faces_detected": len(faces)

    }


# ==========================================
# SAVE FACE CROP
# ==========================================

def save_face_crop(

    face_image,

    output_path

):

    output_path = Path(
        output_path
    )

    output_path.parent.mkdir(

        parents=True,

        exist_ok=True

    )


    success = cv2.imwrite(

        str(output_path),

        face_image

    )


    if not success:

        raise RuntimeError(
            "Failed to save face crop"
        )


    return output_path
"""
Shared feature extraction utilities.

Keep this file synchronized with the Flutter/Node.js feature names.
The trained model expects exactly the same feature order.
"""

from typing import Any


FEATURE_NAMES = [
    "left_eye_openness",
    "right_eye_openness",
    "eye_openness_mean",
    "eye_closure",
    "blink_count",
    "prolonged_closure",
    "visual_fatigue",
    "alertness",
    "abs_yaw",
    "abs_pitch",
    "abs_roll",
    "face_confidence",
    "face_size_ratio",
    "sample_count",
]


def build_feature_dict(
    *,
    left_eye_openness: float,
    right_eye_openness: float,
    blink_count: int,
    prolonged_closure: bool,
    visual_fatigue: float,
    alertness: float,
    yaw: float,
    pitch: float,
    roll: float,
    face_confidence: float,
    face_size_ratio: float,
    sample_count: int,
) -> dict[str, Any]:
    eye_mean = (
        left_eye_openness
        + right_eye_openness
    ) / 2.0

    return {
        "left_eye_openness":
            left_eye_openness,

        "right_eye_openness":
            right_eye_openness,

        "eye_openness_mean":
            eye_mean,

        "eye_closure":
            1.0 - eye_mean,

        "blink_count":
            blink_count,

        "prolonged_closure":
            int(prolonged_closure),

        "visual_fatigue":
            visual_fatigue,

        "alertness":
            alertness,

        "abs_yaw":
            abs(yaw),

        "abs_pitch":
            abs(pitch),

        "abs_roll":
            abs(roll),

        "face_confidence":
            face_confidence,

        "face_size_ratio":
            face_size_ratio,

        "sample_count":
            sample_count,
    }
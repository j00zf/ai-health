from typing import List, Optional

from pydantic import (
    BaseModel,
    Field,
    ConfigDict,
    field_validator,
)


# ============================================================
# USER PROFILE
# ============================================================

class UserProfile(BaseModel):

    model_config = ConfigDict(
        extra="ignore"
    )

    age: Optional[float] = Field(
        default=None,
        ge=0,
        le=120,
    )

    sex: Optional[int] = Field(
        default=None,
        ge=0,
        le=1,
    )

    height_cm: Optional[float] = Field(
        default=None,
        ge=50,
        le=250,
    )

    weight_kg: Optional[float] = Field(
        default=None,
        ge=10,
        le=300,
    )

    bmi: Optional[float] = Field(
        default=None,
        ge=5,
        le=100,
    )

    waist_cm: Optional[float] = Field(
        default=None,
        ge=20,
        le=250,
    )

    heart_rate: Optional[float] = Field(
        default=None,
        ge=20,
        le=250,
    )

    activity_minutes: Optional[float] = Field(
        default=None,
        ge=0,
        le=2000,
    )

    sleep_hours: Optional[float] = Field(
        default=None,
        ge=0,
        le=24,
    )

    smoking: Optional[int] = Field(
        default=None,
        ge=0,
        le=1,
    )

    alcohol: Optional[int] = Field(
        default=None,
        ge=0,
        le=1,
    )


# ============================================================
# DAILY HEALTH RECORD
# ============================================================

class HealthRecord(BaseModel):

    model_config = ConfigDict(
        extra="ignore"
    )

    date: str

    steps: Optional[float] = Field(
        default=None,
        ge=0,
        le=200000,
    )

    activeHours: Optional[float] = Field(
        default=None,
        ge=0,
        le=24,
    )

    activeZoneMinutes: Optional[float] = Field(
        default=None,
        ge=0,
        le=1440,
    )

    heartRate: Optional[float] = Field(
        default=None,
        ge=20,
        le=250,
    )

    restingHeartRate: Optional[float] = Field(
        default=None,
        ge=20,
        le=200,
    )

    sleep: Optional[float] = Field(
        default=None,
        ge=0,
        le=24,
    )

    weight: Optional[float] = Field(
        default=None,
        ge=10,
        le=300,
    )

    bmi: Optional[float] = Field(
        default=None,
        ge=5,
        le=100,
    )

    oxygenSaturation: Optional[float] = Field(
        default=None,
        ge=50,
        le=100,
    )

    calories: Optional[float] = Field(
        default=None,
        ge=0,
        le=20000,
    )

    distance: Optional[float] = Field(
        default=None,
        ge=0,
        le=1000,
    )

    # --------------------------------------------------------
    # DATE VALIDATION
    # --------------------------------------------------------

    @field_validator("date")
    @classmethod
    def validate_date(
        cls,
        value: str,
    ) -> str:

        value = value.strip()

        if not value:
            raise ValueError(
                "date cannot be empty"
            )

        return value


# ============================================================
# ANALYSIS REQUEST
# ============================================================

class AnalyzeRequest(BaseModel):

    model_config = ConfigDict(
        extra="ignore"
    )

    profile: UserProfile

    health_records: List[
        HealthRecord
    ] = Field(
        default_factory=list,
        max_length=366,
    )


# ============================================================
# HEALTH RESPONSE
# ============================================================

class HealthResponse(BaseModel):

    status: str

    service: str

    model_version: str

    blood_pressure_used: bool


# ============================================================
# API ERROR
# ============================================================

class ErrorResponse(BaseModel):

    error: str

    message: str

    code: Optional[str] = None
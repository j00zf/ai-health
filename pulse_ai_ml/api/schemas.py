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
        extra="ignore",
        populate_by_name=True,
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
        ge=0,
        le=250,
    )

    weight_kg: Optional[float] = Field(
        default=None,
        ge=0,
        le=300,
    )

    bmi: Optional[float] = Field(
        default=None,
        ge=0,
        le=100,
    )

    waist_cm: Optional[float] = Field(
        default=None,
        ge=0,
        le=250,
    )

    heart_rate: Optional[float] = Field(
        default=None,
        ge=0,
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

    # Accept additional database fields without failing.
    model_config = ConfigDict(
        extra="ignore",
        populate_by_name=True,
    )

    date: str

    # --------------------------------------------------------
    # ACTIVITY
    # --------------------------------------------------------

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

    # --------------------------------------------------------
    # HEART
    #
    # Zero is allowed because zero may be used by the database
    # as an unavailable/missing-data placeholder.
    # --------------------------------------------------------

    heartRate: Optional[float] = Field(
        default=None,
        ge=0,
        le=250,
    )

    restingHeartRate: Optional[float] = Field(
        default=None,
        ge=0,
        le=250,
    )

    # --------------------------------------------------------
    # SLEEP
    #
    # Matches the actual database/API field:
    # sleepHours
    # --------------------------------------------------------

    sleepHours: Optional[float] = Field(
        default=None,
        ge=0,
        le=24,
    )

    # --------------------------------------------------------
    # BODY MEASUREMENTS
    # --------------------------------------------------------

    weight: Optional[float] = Field(
        default=None,
        ge=0,
        le=300,
    )

    bmi: Optional[float] = Field(
        default=None,
        ge=0,
        le=100,
    )

    # --------------------------------------------------------
    # OXYGEN
    #
    # Matches database/API field:
    # bloodOxygen
    # --------------------------------------------------------

    bloodOxygen: Optional[float] = Field(
        default=None,
        ge=0,
        le=100,
    )

    # --------------------------------------------------------
    # TEMPERATURE
    # --------------------------------------------------------

    bodyTemperature: Optional[float] = Field(
        default=None,
        ge=0,
        le=60,
    )

    # --------------------------------------------------------
    # CALORIES
    # --------------------------------------------------------

    calories: Optional[float] = Field(
        default=None,
        ge=0,
        le=20000,
    )

    # --------------------------------------------------------
    # DISTANCE
    #
    # Matches database/API field:
    # distanceWalked
    # --------------------------------------------------------

    distanceWalked: Optional[float] = Field(
        default=None,
        ge=0,
        le=1000,
    )

    # --------------------------------------------------------
    # FLOORS
    # --------------------------------------------------------

    floors: Optional[float] = Field(
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
        extra="ignore",
        populate_by_name=True,
    )

    profile: UserProfile

    health_records: List[HealthRecord] = Field(
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
# API ERROR RESPONSE
# ============================================================

class ErrorResponse(BaseModel):

    error: str

    message: str

    code: Optional[str] = None
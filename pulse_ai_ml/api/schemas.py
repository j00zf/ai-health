from typing import List, Optional

from pydantic import BaseModel, Field


# ============================================================
# USER PROFILE
# ============================================================

class UserProfile(BaseModel):

    age: Optional[float] = None

    sex: Optional[int] = None

    height_cm: Optional[float] = None

    weight_kg: Optional[float] = None

    bmi: Optional[float] = None

    waist_cm: Optional[float] = None

    heart_rate: Optional[float] = None

    activity_minutes: Optional[float] = None

    sleep_hours: Optional[float] = None

    smoking: Optional[int] = None

    alcohol: Optional[int] = None


# ============================================================
# DAILY HEALTH RECORD
# ============================================================

class HealthRecord(BaseModel):

    date: str

    steps: Optional[float] = None

    activeHours: Optional[float] = None

    activeZoneMinutes: Optional[float] = None

    heartRate: Optional[float] = None

    restingHeartRate: Optional[float] = None

    sleep: Optional[float] = None

    weight: Optional[float] = None

    bmi: Optional[float] = None

    oxygenSaturation: Optional[float] = None

    calories: Optional[float] = None

    distance: Optional[float] = None


# ============================================================
# ANALYSIS REQUEST
# ============================================================

class AnalyzeRequest(BaseModel):

    profile: UserProfile

    health_records: List[HealthRecord] = Field(
        default_factory=list
    )


# ============================================================
# HEALTH CHECK RESPONSE
# ============================================================

class HealthResponse(BaseModel):

    status: str

    service: str

    model_version: str
from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field

Row = Literal["A", "B", "C", "D"]
SpotSize = Literal["compact", "standard", "large", "accessible"]
VehicleType = Literal["compact", "sedan", "suv", "electric"]
Priority = Literal["lifts", "entry"]
SpotState = Literal["free", "occupied", "held"]


class SpotOut(BaseModel):
    id: str
    row: Row
    index: int
    size: SpotSize
    ev: bool
    state: SpotState
    busy: bool = Field(description="Место недоступно для подбора: занято или удерживается")
    updated_at: datetime


class ZoneSummary(BaseModel):
    total: int
    free: int


class SummaryOut(BaseModel):
    total: int
    free: int
    occupied: int
    held: int
    zones: dict[str, ZoneSummary]
    free_by_size: dict[str, int]
    free_ev: int


class RecommendIn(BaseModel):
    vehicle: VehicleType
    charging: bool = False
    accessible: bool = False
    priority: Priority = "entry"
    zone: Row | None = None
    limit: int = Field(default=40, ge=1, le=200)


class RankedSpotOut(BaseModel):
    rank: int
    score: float
    reasons: list[str]
    spot: SpotOut


class RecommendOut(BaseModel):
    spots: list[RankedSpotOut]
    no_fit_reason: str | None = None


class AssignmentIn(BaseModel):
    spot_id: str | None = Field(default=None, description="Если не указано — берётся лучшее место по подбору")
    vehicle: VehicleType
    charging: bool = False
    accessible: bool = False
    priority: Priority = "entry"


class AssignmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    spot_id: str
    vehicle: str
    charging: bool
    accessible: bool
    priority: str
    status: str
    created_at: datetime
    expires_at: datetime
    resolved_at: datetime | None


class SensorEventIn(BaseModel):
    spot_id: str
    occupied: bool
    assignment_id: str | None = Field(
        default=None, description="Если камера/QR опознали автомобиль с назначением — его id"
    )


class SensorEventOut(BaseModel):
    result: str
    spot: SpotOut


class EventOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    ts: datetime
    type: str
    spot_id: str | None
    assignment_id: str | None
    data: dict[str, Any]


class StatsOut(BaseModel):
    window_hours: float
    assignments: dict[str, int]
    assignment_success_rate: float | None = Field(description="Доля назначений, где водитель встал на своё место")
    conflict_rate: float | None = Field(description="Доля назначений, где место занял другой автомобиль")
    time_to_park_p50: float | None
    time_to_park_p90: float | None
    occupancy: float

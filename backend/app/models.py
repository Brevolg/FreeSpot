import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import JSON, Boolean, DateTime, Float, ForeignKey, Index, Integer, String, text
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base, utcnow


class Spot(Base):
    """Машино-место. Геометрия и атрибуты задаются планом объекта, occupied — данными датчиков."""

    __tablename__ = "spots"

    id: Mapped[str] = mapped_column(String(8), primary_key=True)
    row: Mapped[str] = mapped_column(String(1), index=True)
    index: Mapped[int] = mapped_column(Integer)
    size: Mapped[str] = mapped_column(String(16))
    ev: Mapped[bool] = mapped_column(Boolean, default=False)
    occupied: Mapped[bool] = mapped_column(Boolean, default=False)
    walk_cost: Mapped[float] = mapped_column(Float)
    drive_cost: Mapped[float] = mapped_column(Float)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class AssignmentStatus:
    HELD = "held"  # место удерживается за водителем до expires_at
    PARKED = "parked"  # датчик подтвердил парковку на назначенном месте
    MISPARKED = "misparked"  # водитель встал на другое место
    LOST = "lost"  # место занял другой автомобиль (конфликт)
    EXPIRED = "expired"  # водитель не доехал за TTL
    CANCELLED = "cancelled"


class Assignment(Base):
    __tablename__ = "assignments"
    __table_args__ = (
        # не более одного активного удержания на место — защита от гонок
        Index(
            "uq_assignments_active_hold",
            "spot_id",
            unique=True,
            postgresql_where=text("status = 'held'"),
            sqlite_where=text("status = 'held'"),
        ),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    spot_id: Mapped[str] = mapped_column(ForeignKey("spots.id"), index=True)
    vehicle: Mapped[str] = mapped_column(String(16))
    charging: Mapped[bool] = mapped_column(Boolean, default=False)
    accessible: Mapped[bool] = mapped_column(Boolean, default=False)
    priority: Mapped[str] = mapped_column(String(16))
    status: Mapped[str] = mapped_column(String(16), index=True, default=AssignmentStatus.HELD)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, index=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class Event(Base):
    """Журнал событий: изменения занятости, назначения, конфликты."""

    __tablename__ = "events"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    ts: Mapped[datetime] = mapped_column(DateTime, default=utcnow, index=True)
    type: Mapped[str] = mapped_column(String(32), index=True)
    spot_id: Mapped[str | None] = mapped_column(String(8), nullable=True)
    assignment_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    data: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)

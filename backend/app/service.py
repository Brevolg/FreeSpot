"""Бизнес-логика: занятость, подбор, удержание мест, события датчиков, KPI."""

import logging
from collections import Counter as Tally
from datetime import timedelta
from statistics import quantiles

from opentelemetry import trace
from sqlalchemy import delete, func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from . import allocation
from .config import Settings
from .db import utcnow
from .layout import DEMO_OCCUPIED, demo_plan
from .models import Assignment, AssignmentStatus, Event, Spot
from .observability import ASSIGNMENTS, RECOMMEND_LATENCY, RECOMMENDATIONS, SENSOR_EVENTS, SPOTS, TIME_TO_PARK
from .schemas import (
    AssignmentIn,
    RankedSpotOut,
    RecommendIn,
    RecommendOut,
    SensorEventIn,
    SpotOut,
    StatsOut,
    SummaryOut,
    ZoneSummary,
)

log = logging.getLogger("freespot.service")
tracer = trace.get_tracer("freespot.service")


class NotFound(Exception):
    pass


class Conflict(Exception):
    pass


class Unprocessable(Exception):
    pass


# ---------- чтение состояния ----------


async def _active_holds(session: AsyncSession) -> set[str]:
    rows = await session.scalars(
        select(Assignment.spot_id).where(Assignment.status == AssignmentStatus.HELD, Assignment.expires_at > utcnow())
    )
    return set(rows)


def _spot_out(spot: Spot, held: set[str]) -> SpotOut:
    state = "occupied" if spot.occupied else "held" if spot.id in held else "free"
    return SpotOut(
        id=spot.id,
        row=spot.row,  # type: ignore[arg-type]
        index=spot.index,
        size=spot.size,  # type: ignore[arg-type]
        ev=spot.ev,
        state=state,
        busy=state != "free",
        updated_at=spot.updated_at,
    )


async def list_spots(session: AsyncSession) -> list[SpotOut]:
    spots = (await session.scalars(select(Spot).order_by(Spot.row, Spot.index))).all()
    held = await _active_holds(session)
    return [_spot_out(s, held) for s in spots]


async def summary(session: AsyncSession) -> SummaryOut:
    spots = await list_spots(session)
    zones: dict[str, ZoneSummary] = {}
    for s in spots:
        z = zones.setdefault(s.row, ZoneSummary(total=0, free=0))
        z.total += 1
        z.free += not s.busy
    free = [s for s in spots if not s.busy]
    by_size = Tally(s.size for s in free if not s.ev)
    return SummaryOut(
        total=len(spots),
        free=len(free),
        occupied=sum(s.state == "occupied" for s in spots),
        held=sum(s.state == "held" for s in spots),
        zones=zones,
        free_by_size={k: by_size.get(k, 0) for k in ("compact", "standard", "large", "accessible")},
        free_ev=sum(s.ev for s in free),
    )


# ---------- подбор ----------


def _request(data: RecommendIn | AssignmentIn) -> allocation.Request:
    return allocation.Request(
        vehicle=data.vehicle, charging=data.charging, accessible=data.accessible, priority=data.priority
    )


async def _rank(
    session: AsyncSession, req: allocation.Request, settings: Settings
) -> tuple[list[allocation.Ranked], dict[str, Spot], set[str]]:
    spots = (await session.scalars(select(Spot))).all()
    held = await _active_holds(session)
    candidates = [
        allocation.Candidate(
            id=s.id,
            row=s.row,
            size=s.size,
            ev=s.ev,
            available=not s.occupied and s.id not in held,
            walk_cost=s.walk_cost,
            drive_cost=s.drive_cost,
        )
        for s in spots
    ]
    ranked = allocation.rank(
        candidates, req, load_weight=settings.zone_load_weight, large_penalty=settings.large_spot_penalty
    )
    return ranked, {s.id: s for s in spots}, held


async def recommend(session: AsyncSession, data: RecommendIn, settings: Settings) -> RecommendOut:
    req = _request(data)
    with tracer.start_as_current_span("allocation.recommend") as span, RECOMMEND_LATENCY.time():
        span.set_attributes({"vehicle": req.vehicle, "priority": req.priority, "accessible": req.accessible})
        ranked, by_id, held = await _rank(session, req, settings)
        if data.zone:
            ranked = [r for r in ranked if r.spot.row == data.zone]
        span.set_attribute("candidates", len(ranked))

    RECOMMENDATIONS.labels(req.vehicle, req.priority, "found" if ranked else "none").inc()
    return RecommendOut(
        spots=[
            RankedSpotOut(rank=i + 1, score=r.score, reasons=list(r.reasons), spot=_spot_out(by_id[r.spot.id], held))
            for i, r in enumerate(ranked[: data.limit])
        ],
        no_fit_reason=None if ranked else allocation.no_fit_reason(req),
    )


# ---------- назначения ----------


def _resolve(session: AsyncSession, a: Assignment, status: str, **data: object) -> None:
    now = utcnow()
    a.status = status
    a.resolved_at = now
    ASSIGNMENTS.labels(status).inc()
    if status in (AssignmentStatus.PARKED, AssignmentStatus.MISPARKED):
        TIME_TO_PARK.observe((now - a.created_at).total_seconds())
    session.add(Event(type=f"assignment.{status}", spot_id=a.spot_id, assignment_id=a.id, data=dict(data)))
    log.info("assignment resolved", extra={"assignment_id": a.id, "spot_id": a.spot_id, "status": status})


async def expire_holds(session: AsyncSession) -> int:
    stale = (
        await session.scalars(
            select(Assignment).where(Assignment.status == AssignmentStatus.HELD, Assignment.expires_at <= utcnow())
        )
    ).all()
    for a in stale:
        _resolve(session, a, AssignmentStatus.EXPIRED)
    return len(stale)


async def create_assignment(session: AsyncSession, data: AssignmentIn, settings: Settings) -> Assignment:
    await expire_holds(session)
    req = _request(data)
    ranked, by_id, _ = await _rank(session, req, settings)

    if data.spot_id is None:
        if not ranked:
            raise Conflict(allocation.no_fit_reason(req))
        spot_id = ranked[0].spot.id
    else:
        spot_id = data.spot_id.upper()
        if spot_id not in by_id:
            raise NotFound(f"Место {spot_id} не найдено")
        if spot_id not in {r.spot.id for r in ranked}:
            spot = by_id[spot_id]
            candidate = allocation.Candidate(spot.id, spot.row, spot.size, spot.ev, True, 0, 0)
            if not allocation.fits(candidate, req):
                raise Unprocessable(f"Место {spot_id} не подходит под параметры автомобиля")
            raise Conflict(f"Место {spot_id} уже занято или удерживается")

    now = utcnow()
    a = Assignment(
        spot_id=spot_id,
        vehicle=req.vehicle,
        charging=req.charging,
        accessible=req.accessible,
        priority=req.priority,
        status=AssignmentStatus.HELD,
        created_at=now,
        expires_at=now + timedelta(seconds=settings.hold_ttl_seconds),
    )
    session.add(a)
    try:
        await session.flush()
    except IntegrityError as exc:  # параллельный запрос успел удержать то же место
        await session.rollback()
        raise Conflict(f"Место {spot_id} уже удерживается") from exc
    session.add(Event(type="assignment.held", spot_id=spot_id, assignment_id=a.id, data={"vehicle": req.vehicle}))
    await session.commit()
    ASSIGNMENTS.labels(AssignmentStatus.HELD).inc()
    log.info("spot held", extra={"assignment_id": a.id, "spot_id": spot_id, "vehicle": req.vehicle})
    return a


async def get_assignment(session: AsyncSession, assignment_id: str) -> Assignment:
    a = await session.get(Assignment, assignment_id)
    if a is None:
        raise NotFound("Назначение не найдено")
    return a


async def cancel_assignment(session: AsyncSession, assignment_id: str) -> Assignment:
    a = await get_assignment(session, assignment_id)
    if a.status != AssignmentStatus.HELD:
        raise Conflict(f"Назначение уже в статусе {a.status}")
    _resolve(session, a, AssignmentStatus.CANCELLED)
    await session.commit()
    return a


# ---------- датчики ----------


async def sensor_event(session: AsyncSession, data: SensorEventIn) -> tuple[str, SpotOut]:
    spot = await session.get(Spot, data.spot_id.upper())
    if spot is None:
        raise NotFound(f"Место {data.spot_id} не найдено")

    await expire_holds(session)
    hold = await session.scalar(
        select(Assignment).where(Assignment.spot_id == spot.id, Assignment.status == AssignmentStatus.HELD)
    )

    if data.occupied == spot.occupied:
        result = "duplicate"
    elif not data.occupied:
        spot.occupied = False
        result = "freed"
    else:
        spot.occupied = True
        claimed = None
        if data.assignment_id:
            claimed = await session.scalar(
                select(Assignment).where(
                    Assignment.id == data.assignment_id, Assignment.status == AssignmentStatus.HELD
                )
            )
        if claimed is not None and claimed.spot_id == spot.id:
            _resolve(session, claimed, AssignmentStatus.PARKED)
            result = "parked"
        else:
            if claimed is not None:
                _resolve(session, claimed, AssignmentStatus.MISPARKED, actual_spot=spot.id)
            if hold is not None and (claimed is not None or data.assignment_id):
                # место удерживалось за другим водителем, но его занял кто-то ещё — конфликт
                _resolve(session, hold, AssignmentStatus.LOST, taken_by=data.assignment_id)
            elif hold is not None:
                # автомобиль не опознан — считаем, что приехал тот, за кем держали место
                _resolve(session, hold, AssignmentStatus.PARKED, assumed=True)
            result = "misparked" if claimed is not None else "occupied"

    SENSOR_EVENTS.labels("duplicate" if result == "duplicate" else "occupied" if data.occupied else "freed").inc()
    if result != "duplicate":
        spot.updated_at = utcnow()
        session.add(
            Event(
                type=f"spot.{'occupied' if data.occupied else 'freed'}",
                spot_id=spot.id,
                assignment_id=data.assignment_id,
                data={"result": result},
            )
        )
    await session.commit()
    log.info("sensor event", extra={"spot_id": spot.id, "occupied": data.occupied, "result": result})
    return result, _spot_out(spot, await _active_holds(session))


# ---------- журнал и KPI ----------


async def recent_events(session: AsyncSession, limit: int) -> list[Event]:
    return list((await session.scalars(select(Event).order_by(Event.id.desc()).limit(limit))).all())


async def stats(session: AsyncSession, window_hours: float) -> StatsOut:
    since = utcnow() - timedelta(hours=window_hours)
    rows = (await session.scalars(select(Assignment).where(Assignment.created_at >= since))).all()
    by_status = Tally(a.status for a in rows)
    finished = sum(by_status[s] for s in ("parked", "misparked", "lost", "expired"))
    ttp = sorted(
        (a.resolved_at - a.created_at).total_seconds()
        for a in rows
        if a.resolved_at and a.status in (AssignmentStatus.PARKED, AssignmentStatus.MISPARKED)
    )
    p50 = p90 = None
    if len(ttp) == 1:
        p50 = p90 = ttp[0]
    elif ttp:
        q = quantiles(ttp, n=10, method="inclusive")
        p50, p90 = q[4], q[8]
    total = await session.scalar(select(func.count()).select_from(Spot)) or 0
    occupied = await session.scalar(select(func.count()).select_from(Spot).where(Spot.occupied)) or 0
    return StatsOut(
        window_hours=window_hours,
        assignments=dict(by_status),
        assignment_success_rate=round(by_status["parked"] / finished, 4) if finished else None,
        conflict_rate=round(by_status["lost"] / finished, 4) if finished else None,
        time_to_park_p50=p50,
        time_to_park_p90=p90,
        occupancy=round(occupied / total, 4) if total else 0.0,
    )


async def refresh_gauges(session: AsyncSession) -> None:
    counts: dict[tuple[str, str], int] = {}
    spots = await list_spots(session)
    for row in {s.row for s in spots}:
        for state in ("free", "occupied", "held"):
            counts[(row, state)] = 0
    for s in spots:
        counts[(s.row, s.state)] += 1
    for (zone, state), n in counts.items():
        SPOTS.labels(zone, state).set(n)


# ---------- инициализация ----------


async def seed(session: AsyncSession) -> bool:
    if await session.scalar(select(func.count()).select_from(Spot)):
        return False
    now = utcnow()
    for p in demo_plan():
        session.add(
            Spot(
                id=p.id,
                row=p.row,
                index=p.index,
                size=p.size,
                ev=p.ev,
                occupied=p.id in DEMO_OCCUPIED,
                walk_cost=p.walk_cost,
                drive_cost=p.drive_cost,
                updated_at=now,
            )
        )
    await session.commit()
    log.info("demo parking seeded", extra={"spots": len(demo_plan())})
    return True


async def reset_demo(session: AsyncSession) -> None:
    await session.execute(delete(Event))
    await session.execute(delete(Assignment))
    for s in (await session.scalars(select(Spot))).all():
        s.occupied = s.id in DEMO_OCCUPIED
        s.updated_at = utcnow()
    session.add(Event(type="admin.reset", data={}))
    await session.commit()
    log.info("demo state reset")

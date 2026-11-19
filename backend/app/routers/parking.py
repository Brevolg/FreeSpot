from typing import Annotated

from fastapi import APIRouter, Depends, Query, status

from .. import service
from ..deps import SessionDep, SettingsDep, require_api_key
from ..schemas import (
    AssignmentIn,
    AssignmentOut,
    EventOut,
    RecommendIn,
    RecommendOut,
    SensorEventIn,
    SensorEventOut,
    SpotOut,
    StatsOut,
    SummaryOut,
)

router = APIRouter(prefix="/api")


@router.get("/spots", response_model=list[SpotOut], tags=["parking"], summary="Все места и их состояние")
async def get_spots(session: SessionDep) -> list[SpotOut]:
    return await service.list_spots(session)


@router.get("/summary", response_model=SummaryOut, tags=["parking"], summary="Сводка свободных мест")
async def get_summary(session: SessionDep) -> SummaryOut:
    return await service.summary(session)


@router.post("/recommendations", response_model=RecommendOut, tags=["parking"], summary="Подобрать места")
async def post_recommendations(data: RecommendIn, session: SessionDep, settings: SettingsDep) -> RecommendOut:
    return await service.recommend(session, data, settings)


@router.post(
    "/assignments",
    response_model=AssignmentOut,
    status_code=status.HTTP_201_CREATED,
    tags=["assignments"],
    summary="Удержать место за водителем на время TTL",
)
async def post_assignment(data: AssignmentIn, session: SessionDep, settings: SettingsDep) -> AssignmentOut:
    return AssignmentOut.model_validate(await service.create_assignment(session, data, settings))


@router.get("/assignments/{assignment_id}", response_model=AssignmentOut, tags=["assignments"])
async def get_assignment(assignment_id: str, session: SessionDep) -> AssignmentOut:
    return AssignmentOut.model_validate(await service.get_assignment(session, assignment_id))


@router.post("/assignments/{assignment_id}/cancel", response_model=AssignmentOut, tags=["assignments"])
async def cancel_assignment(assignment_id: str, session: SessionDep) -> AssignmentOut:
    return AssignmentOut.model_validate(await service.cancel_assignment(session, assignment_id))


@router.post(
    "/sensors/events",
    response_model=SensorEventOut,
    tags=["sensors"],
    summary="Событие датчика: место занято / освобождено",
    dependencies=[Depends(require_api_key)],
)
async def post_sensor_event(data: SensorEventIn, session: SessionDep) -> SensorEventOut:
    result, spot = await service.sensor_event(session, data)
    return SensorEventOut(result=result, spot=spot)


@router.get("/events", response_model=list[EventOut], tags=["admin"], summary="Журнал событий")
async def get_events(session: SessionDep, limit: Annotated[int, Query(ge=1, le=500)] = 50) -> list[EventOut]:
    return [EventOut.model_validate(e) for e in await service.recent_events(session, limit)]


@router.get("/stats", response_model=StatsOut, tags=["admin"], summary="KPI пилота")
async def get_stats(session: SessionDep, window_hours: Annotated[float, Query(gt=0, le=24 * 31)] = 24) -> StatsOut:
    return await service.stats(session, window_hours)


@router.post(
    "/admin/reset",
    status_code=status.HTTP_204_NO_CONTENT,
    tags=["admin"],
    summary="Вернуть демо-состояние парковки",
    dependencies=[Depends(require_api_key)],
)
async def post_reset(session: SessionDep) -> None:
    await service.reset_demo(session)

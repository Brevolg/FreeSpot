import asyncio
import contextlib
import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text

from . import service
from .config import Settings, get_settings
from .db import Database
from .observability import instrument_app, instrument_engine, setup_logging, setup_tracing
from .routers import parking
from .simulator import Simulator

log = logging.getLogger("freespot")


async def _maintenance(db: Database, interval: float) -> None:
    """Истекает просроченные удержания и обновляет gauge-метрики занятости."""
    while True:
        try:
            async with db.sessions() as s:
                if await service.expire_holds(s):
                    await s.commit()
                await service.refresh_gauges(s)
        except Exception:
            log.exception("maintenance failed")
        await asyncio.sleep(interval)


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or get_settings()
    setup_logging(settings.log_level)
    setup_tracing(settings)

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        db = Database(settings.database_url)
        instrument_engine(db.engine)
        app.state.db = db
        await db.create_schema()
        async with db.sessions() as s:
            await service.seed(s)

        tasks = [asyncio.create_task(_maintenance(db, settings.maintenance_interval_seconds))]
        if settings.simulator_enabled:
            tasks.append(asyncio.create_task(Simulator(db, settings).run()))
        log.info("service started", extra={"env": settings.environment, "simulator": settings.simulator_enabled})
        try:
            yield
        finally:
            for t in tasks:
                t.cancel()
            for t in tasks:
                with contextlib.suppress(asyncio.CancelledError):
                    await t
            await db.dispose()
            log.info("service stopped")

    app = FastAPI(
        title="FreeSpot API",
        root_path=settings.root_path,
        version="1.0.0",
        description="Подбор парковочного места по параметрам автомобиля и текущей занятости.",
        lifespan=lifespan,
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    instrument_app(app)
    app.include_router(parking.router)

    def _error(code: int):  # type: ignore[no-untyped-def]
        async def handler(_: Request, exc: Exception) -> JSONResponse:
            return JSONResponse({"detail": str(exc)}, status_code=code)

        return handler

    app.add_exception_handler(service.NotFound, _error(status.HTTP_404_NOT_FOUND))
    app.add_exception_handler(service.Conflict, _error(status.HTTP_409_CONFLICT))
    app.add_exception_handler(service.Unprocessable, _error(422))

    @app.get("/health", tags=["ops"], summary="Liveness")
    async def health() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/ready", tags=["ops"], summary="Readiness: доступна ли БД")
    async def ready(request: Request) -> JSONResponse:
        try:
            async with request.app.state.db.engine.connect() as conn:
                await conn.execute(text("SELECT 1"))
        except Exception:
            log.exception("readiness check failed")
            return JSONResponse({"status": "unavailable"}, status_code=status.HTTP_503_SERVICE_UNAVAILABLE)
        return {"status": "ok"}  # type: ignore[return-value]

    return app


app = create_app()

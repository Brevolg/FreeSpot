"""Симулятор датчиков для демо: машины приезжают, получают место, паркуются и уезжают.

Загрузка колеблется вокруг 70% ± 20% с периодом 10 минут, чтобы на дашбордах были видны «часы пик».
Часть водителей встаёт не на своё место (конфликты), часть не доезжает (истечение TTL).
"""

import asyncio
import logging
import math
import random
import time

from opentelemetry import trace

from . import service
from .config import Settings
from .db import Database
from .schemas import AssignmentIn, RecommendIn, SensorEventIn

log = logging.getLogger("freespot.simulator")
tracer = trace.get_tracer("freespot.simulator")

VEHICLES = ("compact", "sedan", "suv", "electric")
VEHICLE_WEIGHTS = (2, 5, 2, 1)


class Simulator:
    def __init__(self, db: Database, settings: Settings) -> None:
        self.db = db
        self.settings = settings
        self.rng = random.Random(settings.simulator_seed)
        self.started = time.monotonic()
        self._drives: set[asyncio.Task[None]] = set()

    def target_occupancy(self) -> float:
        phase = (time.monotonic() - self.started) / 600 * 2 * math.pi
        return 0.7 + 0.2 * math.sin(phase)

    async def run(self) -> None:
        log.info("simulator started", extra={"interval_s": self.settings.simulator_interval_seconds})
        try:
            while True:
                try:
                    await self.tick()
                except Exception:
                    log.exception("simulator tick failed")
                await asyncio.sleep(self.settings.simulator_interval_seconds * self.rng.uniform(0.5, 1.5))
        finally:
            for t in self._drives:
                t.cancel()

    async def tick(self) -> None:
        async with self.db.sessions() as s:
            summary = await service.summary(s)
        occupancy = summary.occupied / summary.total  # удержания не считаем: машина ещё едет
        arrive_p = 0.7 if occupancy < self.target_occupancy() else 0.3
        if self.rng.random() < arrive_p:
            await self.arrival()
        else:
            await self.departure()

    async def arrival(self) -> None:
        vehicle = self.rng.choices(VEHICLES, VEHICLE_WEIGHTS)[0]
        params = {
            "vehicle": vehicle,
            "charging": vehicle == "electric" and self.rng.random() < 0.6,
            "accessible": self.rng.random() < 0.05,
            "priority": self.rng.choice(("lifts", "entry")),
        }
        with tracer.start_as_current_span("simulator.arrival", attributes={"vehicle": vehicle}):
            async with self.db.sessions() as s:
                reco = await service.recommend(s, RecommendIn(**params, limit=3), self.settings)
                if not reco.spots:
                    log.info("simulator: no spot for vehicle", extra={"vehicle": vehicle, "reason": reco.no_fit_reason})
                    return
                # обычно водитель берёт лучший вариант, иногда — альтернативу
                pick = reco.spots[0] if self.rng.random() < 0.8 else self.rng.choice(reco.spots)
                try:
                    a = await service.create_assignment(s, AssignmentIn(**params, spot_id=pick.spot.id), self.settings)
                except (service.Conflict, service.Unprocessable):
                    return
        roll = self.rng.random()
        outcome = "own" if roll < 0.88 else "other" if roll < 0.95 else "no_show"
        if outcome == "no_show":
            return
        task = asyncio.create_task(self._drive(a.id, a.spot_id, outcome, self.rng.uniform(3, 25)))
        self._drives.add(task)
        task.add_done_callback(self._drives.discard)

    async def _drive(self, assignment_id: str, spot_id: str, outcome: str, delay: float) -> None:
        await asyncio.sleep(delay)
        with tracer.start_as_current_span("simulator.park", attributes={"outcome": outcome}):
            async with self.db.sessions() as s:
                if outcome == "other":
                    free = [sp.id for sp in await service.list_spots(s) if sp.state != "occupied" and sp.id != spot_id]
                    if not free:
                        return
                    spot_id = self.rng.choice(free)
                try:
                    await service.sensor_event(
                        s, SensorEventIn(spot_id=spot_id, occupied=True, assignment_id=assignment_id)
                    )
                except Exception:
                    log.exception("simulator: park failed")

    async def departure(self) -> None:
        with tracer.start_as_current_span("simulator.departure"):
            async with self.db.sessions() as s:
                occupied = [sp.id for sp in await service.list_spots(s) if sp.state == "occupied"]
                if occupied:
                    await service.sensor_event(s, SensorEventIn(spot_id=self.rng.choice(occupied), occupied=False))

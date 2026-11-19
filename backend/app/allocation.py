"""Алгоритм назначения места. Чистые функции без БД — легко тестировать.

1. Жёсткие ограничения: место свободно, подходит по размеру, разрешено (зарядка, места для маломобильных).
2. Среди допустимых мест минимизируем
       S = расстояние(приоритет) + w_load * загрузка_зоны + штраф_за_широкое_место
   Штраф не даёт тратить редкие широкие места на машины, которым они не нужны.
"""

from collections.abc import Iterable
from dataclasses import dataclass
from typing import Literal

VehicleType = Literal["compact", "sedan", "suv", "electric"]
Priority = Literal["lifts", "entry"]

SIZE_LABEL = {
    "compact": "Компактное",
    "standard": "Стандартное",
    "large": "Широкое",
    "accessible": "Расширенное",
}


@dataclass(frozen=True)
class Request:
    vehicle: VehicleType
    charging: bool = False
    accessible: bool = False
    priority: Priority = "entry"

    @property
    def needs_charger(self) -> bool:
        return self.vehicle == "electric" and self.charging


@dataclass(frozen=True)
class Candidate:
    id: str
    row: str
    size: str
    ev: bool
    available: bool
    walk_cost: float
    drive_cost: float


@dataclass(frozen=True)
class Ranked:
    spot: Candidate
    score: float
    reasons: tuple[str, ...]


def fits(spot: Candidate, req: Request) -> bool:
    """Подходит ли место автомобилю (без учёта занятости)."""
    if req.accessible:
        return spot.size == "accessible" and req.vehicle != "suv" and not (req.needs_charger and not spot.ev)
    if spot.size == "accessible":
        return False
    if req.needs_charger:
        return spot.ev
    if spot.ev and req.vehicle != "electric":
        return False
    if req.vehicle == "suv":
        return spot.size == "large"
    if req.vehicle in ("sedan", "electric"):
        return spot.size != "compact"
    return True


def zone_load(spots: Iterable[Candidate]) -> dict[str, float]:
    total: dict[str, int] = {}
    busy: dict[str, int] = {}
    for s in spots:
        total[s.row] = total.get(s.row, 0) + 1
        busy[s.row] = busy.get(s.row, 0) + (0 if s.available else 1)
    return {row: busy[row] / total[row] for row in total}


def _reasons(spot: Candidate, req: Request, best: bool) -> tuple[str, ...]:
    out = [f"{SIZE_LABEL[spot.size]} место подходит по размеру."]
    if spot.ev and req.charging:
        out.append("На месте есть зарядка.")
    if best:
        out.append(
            "При подборе учтена близость к лифтам" if req.priority == "lifts" else "При подборе учтён путь от въезда"
        )
    return tuple(out)


def rank(
    spots: Iterable[Candidate],
    req: Request,
    *,
    load_weight: float = 60.0,
    large_penalty: float = 25.0,
) -> list[Ranked]:
    spots = list(spots)
    load = zone_load(spots)
    scored: list[tuple[float, Candidate]] = []
    for s in spots:
        if not s.available or not fits(s, req):
            continue
        distance = s.walk_cost if req.priority == "lifts" else s.drive_cost
        penalty = large_penalty if (s.size == "large" and req.vehicle != "suv") else 0.0
        scored.append((distance + load_weight * load.get(s.row, 0.0) + penalty, s))
    scored.sort(key=lambda p: (p[0], p[1].id))
    return [
        Ranked(spot=s, score=round(score, 2), reasons=_reasons(s, req, i == 0)) for i, (score, s) in enumerate(scored)
    ]


def no_fit_reason(req: Request) -> str:
    if req.accessible:
        return "Нет свободного расширенного места нужного размера"
    if req.needs_charger:
        return "Места с зарядкой заняты"
    if req.vehicle == "suv":
        return "Все широкие места заняты"
    return "Свободные места не подходят по размеру"

"""План демо-парковки уровня P1. Совпадает со схемой во фронтенде (frontend/src/parking.ts)."""

from dataclasses import dataclass

ROWS = ("A", "B", "C", "D")
SPOTS_PER_ROW = 10

CELL_W = 80
ROW_EDGE = {"A": 130, "B": 210, "C": 430, "D": 510}
AISLE_Y = {"A": 170, "B": 170, "C": 470, "D": 470}
LIFT = (950, 130)

# Начальная занятость — та же, что была захардкожена во фронтенде
DEMO_OCCUPIED = frozenset(
    "A01 A02 A04 A05 A07 A08 A10 B01 B02 B04 B05 B06 B08 B10 "
    "C01 C02 C03 C04 C05 C06 C08 C09 D01 D02 D03 D05 D07 D09".split()
)


@dataclass(frozen=True)
class SpotPlan:
    id: str
    row: str
    index: int
    size: str
    ev: bool
    walk_cost: float
    drive_cost: float


def _size_for(row: str, i: int) -> str:
    if row == "A" and i >= 8:
        return "accessible"
    if row == "B" and i < 3:
        return "compact"
    if row == "D" and i >= 6:
        return "large"
    return "standard"


def _cell_cx(i: int) -> float:
    return 100 + i * CELL_W + CELL_W / 2


def _walk_cost(row: str, i: int) -> float:
    """Пешком от места до лифтов (условные единицы схемы)."""
    aisle = AISLE_Y[row]
    return abs(ROW_EDGE[row] - aisle) + abs(LIFT[0] - _cell_cx(i)) + abs(aisle - LIFT[1])


def _drive_cost(row: str, i: int) -> float:
    """Проезд от въезда до места (условные единицы схемы)."""
    return AISLE_Y[row] + (_cell_cx(i) - 45) + 40


def demo_plan() -> list[SpotPlan]:
    return [
        SpotPlan(
            id=f"{row}{i + 1:02d}",
            row=row,
            index=i,
            size=_size_for(row, i),
            ev=row == "C" and i < 4,
            walk_cost=_walk_cost(row, i),
            drive_cost=_drive_cost(row, i),
        )
        for row in ROWS
        for i in range(SPOTS_PER_ROW)
    ]

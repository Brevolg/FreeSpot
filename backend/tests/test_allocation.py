import pytest

from app.allocation import Candidate, Request, fits, no_fit_reason, rank
from app.layout import DEMO_OCCUPIED, demo_plan


def cand(id="A01", row="A", size="standard", ev=False, available=True, walk=100.0, drive=100.0) -> Candidate:  # type: ignore[no-untyped-def]
    return Candidate(id, row, size, ev, available, walk, drive)


def demo(occupied=DEMO_OCCUPIED) -> list[Candidate]:  # type: ignore[no-untyped-def]
    return [Candidate(p.id, p.row, p.size, p.ev, p.id not in occupied, p.walk_cost, p.drive_cost) for p in demo_plan()]


@pytest.mark.parametrize(
    ("size", "ev", "req", "expected"),
    [
        ("standard", False, Request("sedan"), True),
        ("compact", False, Request("sedan"), False),
        ("compact", False, Request("compact"), True),
        ("standard", False, Request("suv"), False),
        ("large", False, Request("suv"), True),
        ("standard", True, Request("sedan"), False),  # обычной машине нельзя на место с зарядкой
        ("standard", True, Request("electric", charging=True), True),
        ("standard", False, Request("electric", charging=True), False),
        ("standard", True, Request("electric"), True),
        ("accessible", False, Request("sedan"), False),  # без права — нельзя на место для маломобильных
        ("accessible", False, Request("sedan", accessible=True), True),
        ("standard", False, Request("sedan", accessible=True), False),
        ("accessible", False, Request("suv", accessible=True), False),
    ],
)
def test_fits(size: str, ev: bool, req: Request, expected: bool) -> None:
    assert fits(cand(size=size, ev=ev), req) is expected


def test_rank_skips_unavailable_and_unfit() -> None:
    spots = [cand("A01", available=False), cand("A02", size="compact"), cand("A03")]
    assert [r.spot.id for r in rank(spots, Request("sedan"))] == ["A03"]


def test_rank_uses_priority_distance() -> None:
    near_lift = cand("A01", walk=10, drive=500)
    near_entry = cand("A02", walk=500, drive=10)
    assert rank([near_lift, near_entry], Request("sedan", priority="lifts"))[0].spot.id == "A01"
    assert rank([near_lift, near_entry], Request("sedan", priority="entry"))[0].spot.id == "A02"


def test_rank_saves_large_spots_for_suv() -> None:
    large = cand("D07", row="D", size="large", drive=100)
    standard = cand("D05", row="D", size="standard", drive=110)
    assert rank([large, standard], Request("sedan"))[0].spot.id == "D05"
    assert [r.spot.id for r in rank([large, standard], Request("suv"))] == ["D07"]


def test_rank_prefers_less_loaded_zone() -> None:
    busy_zone = [cand("A01", drive=100), *[cand(f"A0{i}", available=False) for i in range(2, 6)]]
    free_zone = [cand("B01", row="B", drive=120), *[cand(f"B0{i}", row="B") for i in range(2, 6)]]
    best = rank(busy_zone + free_zone, Request("sedan"), load_weight=60)[0]
    assert best.spot.row == "B"


def test_only_best_spot_gets_priority_reason() -> None:
    ranked = rank(demo(), Request("sedan"))
    assert any("въезда" in r for r in ranked[0].reasons)
    assert not any("въезда" in r for r in ranked[1].reasons)


def test_demo_layout_matches_frontend() -> None:
    plan = demo_plan()
    assert len(plan) == 40
    assert [p.id for p in plan if p.ev] == ["C01", "C02", "C03", "C04"]
    assert [p.id for p in plan if p.size == "accessible"] == ["A09", "A10"]
    assert [p.id for p in plan if p.size == "large"] == ["D07", "D08", "D09", "D10"]
    assert sum(p.id not in DEMO_OCCUPIED for p in plan) == 12


def test_demo_has_no_free_charger() -> None:
    assert rank(demo(), Request("electric", charging=True)) == []
    assert no_fit_reason(Request("electric", charging=True)) == "Места с зарядкой заняты"

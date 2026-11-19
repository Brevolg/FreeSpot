from fastapi.testclient import TestClient


def test_health_and_ready(client: TestClient) -> None:
    assert client.get("/health").json() == {"status": "ok"}
    assert client.get("/ready").status_code == 200


def test_spots_seeded_with_demo_occupancy(client: TestClient) -> None:
    spots = client.get("/api/spots").json()
    assert len(spots) == 40
    a01 = next(s for s in spots if s["id"] == "A01")
    a03 = next(s for s in spots if s["id"] == "A03")
    assert a01["busy"] and a01["state"] == "occupied"
    assert not a03["busy"] and a03["state"] == "free"


def test_summary(client: TestClient) -> None:
    s = client.get("/api/summary").json()
    assert (s["total"], s["free"], s["occupied"], s["held"]) == (40, 12, 28, 0)
    assert sum(z["free"] for z in s["zones"].values()) == 12


def test_recommendation_and_zone_filter(client: TestClient) -> None:
    r = client.post("/api/recommendations", json={"vehicle": "sedan"}).json()
    assert r["no_fit_reason"] is None
    assert [x["rank"] for x in r["spots"]] == list(range(1, len(r["spots"]) + 1))
    assert all(not x["spot"]["busy"] for x in r["spots"])

    zone_b = client.post("/api/recommendations", json={"vehicle": "sedan", "zone": "B"}).json()
    assert zone_b["spots"] and all(x["spot"]["row"] == "B" for x in zone_b["spots"])


def test_recommendation_no_fit(client: TestClient) -> None:
    r = client.post("/api/recommendations", json={"vehicle": "electric", "charging": True}).json()
    assert r["spots"] == []
    assert r["no_fit_reason"] == "Места с зарядкой заняты"


def test_validation_error(client: TestClient) -> None:
    assert client.post("/api/recommendations", json={"vehicle": "tank"}).status_code == 422


def test_hold_hides_spot_and_sensor_confirms(client: TestClient, sensor_headers: dict[str, str]) -> None:
    a = client.post("/api/assignments", json={"vehicle": "sedan"})
    assert a.status_code == 201
    a = a.json()
    assert a["status"] == "held"

    reco = client.post("/api/recommendations", json={"vehicle": "sedan"}).json()
    assert a["spot_id"] not in {x["spot"]["id"] for x in reco["spots"]}
    assert client.post("/api/assignments", json={"vehicle": "sedan", "spot_id": a["spot_id"]}).status_code == 409

    ev = client.post(
        "/api/sensors/events",
        json={"spot_id": a["spot_id"], "occupied": True, "assignment_id": a["id"]},
        headers=sensor_headers,
    ).json()
    assert ev["result"] == "parked" and ev["spot"]["state"] == "occupied"
    assert client.get(f"/api/assignments/{a['id']}").json()["status"] == "parked"

    stats = client.get("/api/stats").json()
    assert stats["assignments"] == {"parked": 1}
    assert stats["assignment_success_rate"] == 1.0
    assert stats["time_to_park_p50"] is not None


def test_conflict_when_other_car_takes_held_spot(client: TestClient, sensor_headers: dict[str, str]) -> None:
    first = client.post("/api/assignments", json={"vehicle": "sedan"}).json()
    second = client.post("/api/assignments", json={"vehicle": "sedan"}).json()
    assert first["spot_id"] != second["spot_id"]

    # второй водитель встал на место первого
    ev = client.post(
        "/api/sensors/events",
        json={"spot_id": first["spot_id"], "occupied": True, "assignment_id": second["id"]},
        headers=sensor_headers,
    ).json()
    assert ev["result"] == "misparked"
    assert client.get(f"/api/assignments/{first['id']}").json()["status"] == "lost"
    assert client.get(f"/api/assignments/{second['id']}").json()["status"] == "misparked"
    assert client.get("/api/stats").json()["conflict_rate"] == 0.5


def test_spot_validation_on_assignment(client: TestClient) -> None:
    assert client.post("/api/assignments", json={"vehicle": "sedan", "spot_id": "Z99"}).status_code == 404
    assert client.post("/api/assignments", json={"vehicle": "suv", "spot_id": "A03"}).status_code == 422
    assert client.post("/api/assignments", json={"vehicle": "sedan", "spot_id": "A01"}).status_code == 409


def test_cancel(client: TestClient) -> None:
    a = client.post("/api/assignments", json={"vehicle": "compact"}).json()
    assert client.post(f"/api/assignments/{a['id']}/cancel").json()["status"] == "cancelled"
    assert client.post(f"/api/assignments/{a['id']}/cancel").status_code == 409


def test_sensor_requires_key_and_frees_spot(client: TestClient, sensor_headers: dict[str, str]) -> None:
    assert client.post("/api/sensors/events", json={"spot_id": "A01", "occupied": False}).status_code == 401
    r = client.post("/api/sensors/events", json={"spot_id": "a01", "occupied": False}, headers=sensor_headers).json()
    assert r["result"] == "freed" and not r["spot"]["busy"]
    again = client.post("/api/sensors/events", json={"spot_id": "A01", "occupied": False}, headers=sensor_headers)
    assert again.json()["result"] == "duplicate"


def test_events_and_reset(client: TestClient, sensor_headers: dict[str, str]) -> None:
    client.post("/api/sensors/events", json={"spot_id": "A01", "occupied": False}, headers=sensor_headers)
    assert client.get("/api/events").json()[0]["type"] == "spot.freed"
    assert client.post("/api/admin/reset", headers=sensor_headers).status_code == 204
    assert client.get("/api/summary").json()["free"] == 12


def test_metrics_exposed(client: TestClient) -> None:
    client.post("/api/recommendations", json={"vehicle": "sedan"})
    body = client.get("/metrics").text
    assert "freespot_recommendations_total" in body
    assert "http_request_duration_seconds" in body

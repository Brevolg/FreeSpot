# FreeSpot backend

FastAPI + SQLAlchemy (async) + PostgreSQL. Подбирает место, удерживает его за водителем, принимает события датчиков, считает KPI пилота и отдаёт метрики, логи и трейсы.

## Запуск

```bash
python -m venv .venv && .venv/bin/pip install -r requirements-dev.txt
.venv/bin/uvicorn app.main:app --reload          # http://localhost:8000/docs
.venv/bin/pytest                                  # тесты
.venv/bin/ruff check . && .venv/bin/ruff format --check .
```

По умолчанию используется SQLite (`./freespot.db`), а в Docker — PostgreSQL. При первом старте создаётся схема и демо-парковка P1 на 40 мест (тот же план, что во фронтенде).

## Настройки (переменные окружения)

| Переменная | По умолчанию | Назначение |
| --- | --- | --- |
| `FREESPOT_DATABASE_URL` | `sqlite+aiosqlite:///./freespot.db` | Строка подключения к БД, для Postgres: `postgresql+asyncpg://…` |
| `FREESPOT_HOLD_TTL_SECONDS` | `300` | Сколько держать место за водителем |
| `FREESPOT_ZONE_LOAD_WEIGHT` | `60` | Вес загрузки зоны в функции ранжирования |
| `FREESPOT_LARGE_SPOT_PENALTY` | `25` | Штраф за широкое место для машины, которой оно не нужно |
| `FREESPOT_SIMULATOR_ENABLED` | `false` | Включить симулятор датчиков |
| `FREESPOT_SIMULATOR_INTERVAL_SECONDS` | `3` | Средний интервал между событиями симулятора |
| `FREESPOT_API_KEY` | — | Если задан, `/api/sensors/*` и `/api/admin/*` требуют заголовок `X-Api-Key` |
| `FREESPOT_OTEL_EXPORTER_OTLP_ENDPOINT` | — | OTLP HTTP endpoint для трейсов, например `http://jaeger:4318` |
| `FREESPOT_LOG_LEVEL` | `INFO` | Уровень логов |
| `FREESPOT_CORS_ORIGINS` | localhost-адреса | JSON-список разрешённых origin |

## API

| Метод | Путь | Что делает |
| --- | --- | --- |
| GET | `/api/spots` | Все места: `state` = `free` / `occupied` / `held`, `busy` = недоступно для подбора |
| GET | `/api/summary` | Свободные места всего, по зонам и типам |
| POST | `/api/recommendations` | Подбор: `{vehicle, charging, accessible, priority, zone?}` → места по порядку, причины, `no_fit_reason` |
| POST | `/api/assignments` | Удержать место (без `spot_id` берётся лучшее) на `HOLD_TTL` |
| GET | `/api/assignments/{id}` | Статус назначения |
| POST | `/api/assignments/{id}/cancel` | Отменить удержание |
| POST | `/api/sensors/events` | Датчик: `{spot_id, occupied, assignment_id?}` 🔑 |
| GET | `/api/events` | Журнал событий |
| GET | `/api/stats?window_hours=24` | KPI: Assignment Success Rate, Conflict Rate, Time to Park P50/P90, загрузка |
| POST | `/api/admin/reset` | Вернуть демо-состояние 🔑 |
| GET | `/health`, `/ready` | Liveness и readiness (проверка БД) |
| GET | `/metrics` | Метрики Prometheus |

Пример:

```bash
curl -s localhost:8000/api/recommendations -H 'content-type: application/json' \
  -d '{"vehicle":"sedan","priority":"lifts"}' | jq '.spots[0]'
```

## Алгоритм назначения

1. **Жёсткие ограничения** (`allocation.fits`). Место должно быть свободно и не удерживаться, подходить по размеру (внедорожнику нужно широкое место, седану — не компактное), места с зарядкой отдаются только электромобилям, а места для маломобильных — только при отмеченном флаге.
2. **Ранжирование** допустимых мест по формуле
   `S = расстояние(приоритет) + w_load · загрузка_зоны + штраф_за_широкое`.
   Расстояние считается либо пешком до лифтов, либо проездом от въезда, в зависимости от выбранного приоритета. Загрузка зоны распределяет машины по парковке, а штраф бережёт широкие места для внедорожников.

Логика оформлена чистыми функциями без БД и покрыта тестами в `tests/test_allocation.py`.

## Жизненный цикл назначения

```
held ──датчик: занято, тот же автомобиль──▶ parked
  │ ──водитель встал на другое место────────▶ misparked
  │ ──место занял другой автомобиль─────────▶ lost       (конфликт)
  │ ──истёк TTL─────────────────────────────▶ expired
  └──отмена─────────────────────────────────▶ cancelled
```

Удерживать одно место может только одно назначение: это гарантирует частичный уникальный индекс `uq_assignments_active_hold`, так что при гонке второй запрос получит 409.

## Наблюдаемость

- **Логи**: JSON в stdout с `trace_id` и `span_id`, плюс access-лог (метод, путь, статус, `duration_ms`, `request_id`). В Docker их собирает Alloy и отправляет в Loki.
- **Метрики** (`/metrics`):
  - HTTP: `http_requests_total`, `http_request_duration_seconds`;
  - бизнес: `freespot_recommendations_total{result}`, `freespot_assignments_total{status}`, `freespot_time_to_park_seconds`, `freespot_spots{zone,state}`, `freespot_sensor_events_total`, `freespot_recommend_duration_seconds`.
- **Трейсы**: OpenTelemetry. Инструментированы FastAPI и SQLAlchemy, плюс собственные спаны `allocation.recommend` и `simulator.*`. Экспорт по OTLP в Jaeger.
- **Алерты** (`deploy/prometheus/alerts.yml`): бэкенд недоступен, доля 5xx выше 5%, медленный подбор, Assignment Success Rate ниже 80%, парковка заполнена.

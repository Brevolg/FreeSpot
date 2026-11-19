# FreeSpot — система оптимальной парковки

Сервис подбирает парковочное место в зависимости от типа автомобиля, его потребностей (зарядка, место для маломобильных) и текущей занятости парковки.

```
           ┌──────────────┐  /api   ┌──────────────┐        ┌────────────┐
браузер ──▶│ frontend     │────────▶│ backend      │───────▶│ PostgreSQL │
           │ nginx + React│         │ FastAPI      │        └────────────┘
           └──────────────┘         │ + симулятор  │
                                    └──────┬───────┘
              /metrics ┌────────────┐      │ OTLP   ┌────────┐
              ◀────────│ Prometheus │      └───────▶│ Jaeger │
                       └─────┬──────┘               └───┬────┘
   stdout (JSON) ─▶ Alloy ─▶ Loki ──┐                   │
                                    ▼                   ▼
                                 ┌──────────────────────────┐
                                 │ Grafana: дашборд + логи  │
                                 └──────────────────────────┘
```

| Каталог | Что внутри |
| --- | --- |
| `frontend/` | React + Vite, схема парковки и подбор места ([README](frontend/README.md)) |
| `backend/` | FastAPI, алгоритм назначения, датчики, KPI, симулятор ([README](backend/README.md)) |
| `deploy/` | Конфиги Prometheus (+ алерты), Loki/Alloy, Grafana (источники и дашборд) |
| `docker-compose.yml` | Весь стек одной командой |

## Быстрый старт (Docker)

```bash
docker compose up -d --build
```

| Адрес | Что |
| --- | --- |
| http://localhost:8080 | Приложение |
| http://localhost:8080/docs | Swagger API |
| http://localhost:3000 | Grafana (admin / admin), дашборд «FreeSpot — парковка и сервис» |
| http://localhost:9090 | Prometheus (только localhost) |
| http://localhost:16686 | Jaeger, трейсы (только localhost) |

Порты и пароли переопределяются переменными `FRONTEND_PORT`, `GRAFANA_PORT`, `GRAFANA_PASSWORD`, `POSTGRES_PASSWORD`, `FREESPOT_API_KEY` (можно положить в `.env` рядом с `docker-compose.yml`).

Симулятор датчиков включён по умолчанию: машины приезжают, получают место, паркуются и уезжают, так что схема на фронте и графики в Grafana обновляются сами. Отключить: `FREESPOT_SIMULATOR_ENABLED=false`.

## Разработка без Docker

```bash
# бэкенд (SQLite по умолчанию)
cd backend
python -m venv .venv && .venv/bin/pip install -r requirements-dev.txt
FREESPOT_SIMULATOR_ENABLED=true .venv/bin/uvicorn app.main:app --reload

# фронтенд, в другом терминале: Vite проксирует /api на :8000
cd frontend
pnpm install && pnpm dev
```

## Деплой в облако

Подойдёт любая VM с Docker (Yandex Cloud, MTS Cloud, VK Cloud и т.п.), 2 vCPU и 4 ГБ RAM:

```bash
git clone <repo> && cd FreeSpot
cat > .env <<EOF
POSTGRES_PASSWORD=<сложный пароль>
FREESPOT_API_KEY=<ключ для датчиков>
GRAFANA_PASSWORD=<пароль grafana>
FRONTEND_PORT=80
EOF
docker compose up -d --build
```

Наружу открыты только `FRONTEND_PORT` и `GRAFANA_PORT`, а Prometheus и Jaeger привязаны к 127.0.0.1 (смотреть через `ssh -L`). Для HTTPS поставьте перед фронтом Caddy или Nginx с Let's Encrypt.

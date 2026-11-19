"""Логи (JSON в stdout + trace_id), метрики Prometheus и трейсы OpenTelemetry."""

import json
import logging
import sys
import time
import uuid
from datetime import UTC, datetime

from fastapi import FastAPI, Request, Response
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from prometheus_client import Counter, Gauge, Histogram
from prometheus_fastapi_instrumentator import Instrumentator
from sqlalchemy.ext.asyncio import AsyncEngine

from .config import Settings

log = logging.getLogger("freespot")

# ---------- бизнес-метрики (см. раздел 7 бизнес-анализа) ----------

RECOMMENDATIONS = Counter(
    "freespot_recommendations_total",
    "Запросы на подбор места",
    ["vehicle", "priority", "result"],  # result: found | none
)
RECOMMEND_LATENCY = Histogram(
    "freespot_recommend_duration_seconds",
    "Время расчёта рекомендации",
    buckets=(0.001, 0.0025, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1),
)
ASSIGNMENTS = Counter(
    "freespot_assignments_total",
    "Переходы статусов назначений",
    ["status"],  # held | parked | misparked | lost | expired | cancelled
)
TIME_TO_PARK = Histogram(
    "freespot_time_to_park_seconds",
    "Время от назначения места до фактической парковки (Time to Park)",
    buckets=(5, 10, 20, 30, 45, 60, 90, 120, 180, 300, 600),
)
SENSOR_EVENTS = Counter(
    "freespot_sensor_events_total",
    "События от датчиков занятости",
    ["kind"],  # occupied | freed | duplicate
)
SPOTS = Gauge("freespot_spots", "Места по зонам и состояниям", ["zone", "state"])  # free | occupied | held


# ---------- логи ----------

_STD_ATTRS = set(vars(logging.makeLogRecord({}))) | {"message", "asctime", "taskName", "color_message"}


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, object] = {
            "ts": datetime.fromtimestamp(record.created, UTC).isoformat(timespec="milliseconds"),
            "level": record.levelname.lower(),
            "logger": record.name,
            "msg": record.getMessage(),
        }
        ctx = trace.get_current_span().get_span_context()
        if ctx.is_valid:
            payload["trace_id"] = format(ctx.trace_id, "032x")
            payload["span_id"] = format(ctx.span_id, "016x")
        for key, value in vars(record).items():
            if key not in _STD_ATTRS and not key.startswith("_"):
                payload[key] = value
        if record.exc_info:
            payload["exc"] = self.formatException(record.exc_info)
        return json.dumps(payload, ensure_ascii=False, default=str)


def setup_logging(level: str) -> None:
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    root = logging.getLogger()
    root.handlers[:] = [handler]
    root.setLevel(level.upper())
    for name in ("uvicorn", "uvicorn.error"):
        logging.getLogger(name).handlers[:] = []
        logging.getLogger(name).propagate = True
    logging.getLogger("uvicorn.access").disabled = True  # свой access-лог ниже


# ---------- трейсы ----------

_tracing_ready = False


def setup_tracing(settings: Settings) -> None:
    global _tracing_ready
    if _tracing_ready:
        return
    provider = TracerProvider(
        resource=Resource.create(
            {"service.name": settings.service_name, "deployment.environment": settings.environment}
        )
    )
    if settings.otel_exporter_otlp_endpoint:
        endpoint = settings.otel_exporter_otlp_endpoint.rstrip("/") + "/v1/traces"
        provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint=endpoint)))
    trace.set_tracer_provider(provider)
    _tracing_ready = True


def instrument_engine(engine: AsyncEngine) -> None:
    SQLAlchemyInstrumentor().instrument(engine=engine.sync_engine)


# ---------- подключение к приложению ----------


def instrument_app(app: FastAPI) -> None:
    Instrumentator(excluded_handlers=["/metrics", "/health", "/ready"]).instrument(app).expose(
        app, endpoint="/metrics", include_in_schema=False
    )
    FastAPIInstrumentor.instrument_app(app, excluded_urls="metrics,health,ready")

    @app.middleware("http")
    async def access_log(request: Request, call_next) -> Response:  # type: ignore[no-untyped-def]
        request_id = request.headers.get("x-request-id") or uuid.uuid4().hex
        start = time.perf_counter()
        try:
            response = await call_next(request)
        except Exception:
            log.exception("unhandled error", extra={"path": request.url.path, "request_id": request_id})
            raise
        if request.url.path not in ("/metrics", "/health", "/ready"):
            log.info(
                "request",
                extra={
                    "method": request.method,
                    "path": request.url.path,
                    "status": response.status_code,
                    "duration_ms": round((time.perf_counter() - start) * 1000, 2),
                    "request_id": request_id,
                },
            )
        response.headers["x-request-id"] = request_id
        return response

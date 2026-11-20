from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Настройки сервиса. Все переменные окружения начинаются с FREESPOT_."""

    model_config = SettingsConfigDict(env_prefix="FREESPOT_", env_file=".env", extra="ignore")

    service_name: str = "freespot-backend"
    environment: str = "local"
    root_path: str = ""
    log_level: str = "INFO"

    database_url: str = "sqlite+aiosqlite:///./freespot.db"

    # Мягкое удержание места за водителем (soft-assignment), секунды
    hold_ttl_seconds: int = 300
    # Веса функции ранжирования: S = расстояние + w_load * загрузка_зоны + штраф_за_широкое
    zone_load_weight: float = 60.0
    large_spot_penalty: float = 25.0

    # Фоновое обслуживание: истечение удержаний, обновление метрик
    maintenance_interval_seconds: float = 5.0

    # Симулятор датчиков для демо
    simulator_enabled: bool = False
    simulator_interval_seconds: float = 3.0
    simulator_seed: int | None = None

    # Ключ для датчиков и админ-операций. Если пусто — проверка отключена (локальная разработка)
    api_key: str | None = None

    cors_origins: list[str] = ["http://localhost:8443", "http://localhost:5173", "http://localhost:8080"]

    # OTLP HTTP endpoint, например http://jaeger:4318. Если пусто — трейсы не экспортируются
    otel_exporter_otlp_endpoint: str | None = None


@lru_cache
def get_settings() -> Settings:
    return Settings()

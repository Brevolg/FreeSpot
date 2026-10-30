import { Button, Card, Icon, ToggleChip } from "./ui"
import { SPOTS, SIZE_INFO, ZONE_INFO, VEHICLES, reasonsFor, routeSteps, type VehicleType, type Priority, type Spot, type Options } from "./parking"

export type Phase = "idle" | "done"

export function VehiclePanel({
  vehicle,
  onVehicle,
  charging,
  setCharging,
  accessible,
  setAccessible,
  priority,
  setPriority,
  onReset,
}: {
  vehicle: VehicleType | null
  onVehicle: (v: VehicleType) => void
  charging: boolean
  setCharging: (v: boolean) => void
  accessible: boolean
  setAccessible: (v: boolean) => void
  priority: Priority
  setPriority: (p: Priority) => void
  onReset: () => void
}) {
  return (
    <Card
      title="Ваш автомобиль"
      className="card--vehicle"
      action={
        vehicle && (
          <button type="button" className="text-btn" onClick={onReset}>
            <Icon name="reset" size={14} /> Сбросить
          </button>
        )
      }
    >
      <div className="vehicles" role="radiogroup" aria-label="Тип автомобиля">
        {VEHICLES.map((v) => (
          <button
            key={v.id}
            type="button"
            role="radio"
            aria-checked={vehicle === v.id}
            className={`vehicle ${vehicle === v.id ? "is-selected" : ""}`}
            onClick={() => onVehicle(v.id)}
          >
            <Icon name={v.id} size={26} />
            <b>{v.label}</b>
            <small>{v.dims}</small>
          </button>
        ))}
      </div>
      <div className="conditions">
        {vehicle === "electric" && (
          <ToggleChip
            checked={charging}
            onChange={() => setCharging(!charging)}
            icon="bolt"
          >
            Нужна зарядка
          </ToggleChip>
        )}
        <ToggleChip
          checked={accessible}
          onChange={() => setAccessible(!accessible)}
          icon="wheelchair"
        >
          Маломобильным
        </ToggleChip>
      </div>
      <div className="segmented" role="radiogroup" aria-label="Приоритет">
        {([
          ["lifts", "Ближе к лифтам", "walk"],
          ["entry", "Быстрее доехать", "route"],
        ] as const).map(([value, label, icon]) => (
          <button
            key={value}
            type="button"
            role="radio"
            aria-checked={priority === value}
            className={priority === value ? "is-active" : ""}
            onClick={() => setPriority(value)}
          >
            <Icon name={icon} size={15} /> {label}
          </button>
        ))}
      </div>
    </Card>
  )
}

export function AvailabilityPanel({ fitCount }: { fitCount: number | null }) {
  const free = SPOTS.filter((s) => !s.busy)
  const stats = [
    {
      label: "Стандартные",
      value: free.filter((s) => s.size === "standard" && !s.ev).length,
    },
    {
      label: "Компактные",
      value: free.filter((s) => s.size === "compact").length,
    },
    { label: "Широкие", value: free.filter((s) => s.size === "large").length },
    { label: "С зарядкой", value: free.filter((s) => s.ev).length },
  ]
  return (
    <Card title="Свободные места" className="card--availability">
      <div className="avail">
        <div className="avail__main">
          <strong>{free.length}</strong>
          <span>из {SPOTS.length} мест</span>
        </div>
        <div className="avail__bar">
          <i style={{ width: `${(free.length / SPOTS.length) * 100}%` }} />
        </div>
        {fitCount !== null && (
          <div className={`avail__fit ${fitCount === 0 ? "is-zero" : ""}`}>
            <Icon name={fitCount ? "check" : "x"} size={15} />
            Под ваш запрос: <b>{fitCount}</b>
          </div>
        )}
        <div className="avail__stats">
          {stats.map((s) => (
            <div key={s.label} className={s.value === 0 ? "is-zero" : ""}>
              <b>{s.value}</b>
              <span>{s.label}</span>
            </div>
          ))}
        </div>
      </div>
    </Card>
  )
}

export function RecommendationPanel({
  options,
  spot,
  ranked,
  onPick,
  onWithoutCharging,
  onWithoutAccessible,
  onReset,
}: {
  options: Options | null
  spot?: Spot
  ranked: Spot[]
  onPick: (s: Spot) => void
  onWithoutCharging: () => void
  onWithoutAccessible: () => void
  onReset: () => void
}) {
  if (!options) {
    return (
      <Card title="Подбор места" className="card--reco">
        <div className="placeholder">
          <span className="placeholder__icon">
            <Icon name="pin" size={22} />
          </span>
          <b>Выберите автомобиль</b>
          <p>
            После выбора покажем свободные места, которые подходят по размеру.
          </p>
        </div>
      </Card>
    )
  }

  if (!spot) {
    const needsCharger = options.vehicle === "electric" && options.charging
    const reason = options.accessible
      ? "Нет свободного расширенного места нужного размера"
      : needsCharger
        ? "Места с зарядкой заняты"
        : options.vehicle === "suv"
          ? "Все широкие места заняты"
          : "Свободные места не подходят по размеру"
    return (
      <Card title="Рекомендация" className="card--reco">
        <div className="empty">
          <span className="empty__icon">
            <Icon name="search" size={22} />
            <i>
              <Icon name="x" size={10} />
            </i>
          </span>
          <b>Подходящих мест нет</b>
          <p>{reason}. Попробуйте изменить условия подбора.</p>
        </div>
        <div className="stack">
          {needsCharger && (
            <Button onClick={onWithoutCharging}>
              <Icon name="electric" size={18} /> Подобрать без зарядки
            </Button>
          )}
          {options.accessible && (
            <Button onClick={onWithoutAccessible}>
              Показать обычные места
            </Button>
          )}
          <Button variant="soft" onClick={onReset}>
            Изменить автомобиль
          </Button>
        </div>
      </Card>
    )
  }

  const isBest = ranked[0]?.id === spot.id
  // Те же варианты и номера, что на схеме.
  const others = ranked
    .slice(0, 4)
    .filter((s) => s.id !== spot.id)
    .slice(0, 3)

  return (
    <Card
      title={isBest ? "Рекомендуем" : "Выбранный вариант"}
      className="card--reco"
    >
      <div className="reco" aria-live="polite">
        <div className="reco__head">
          <div className="reco__id">
            <small>место</small>
            {spot.id}
          </div>
          <div className="reco__meta">
            <b>
              Зона {spot.row} · {ZONE_INFO[spot.row]}
            </b>
            <span>
              {SIZE_INFO[spot.size].label} · {SIZE_INFO[spot.size].dims}
            </span>
            <div className="reco__metrics">
              <span>
                <Icon name="route" size={14} /> Проезд{" "}
                {spot.row === "A" || spot.row === "B" ? 1 : 2}
              </span>
            </div>
          </div>
        </div>
        <div className="reco__why">
          <p>{reasonsFor(spot, options, isBest).join(" ")}</p>
        </div>
        {others.length > 0 && (
          <div className="reco__alts">
            <span className="overline">Другие подходящие</span>
            <div className="alt-list">
              {others.map((s) => (
                <button
                  key={s.id}
                  type="button"
                  className="alt"
                  onClick={() => onPick(s)}
                >
                  <i>{ranked.indexOf(s) + 1}</i>
                  <b>{s.id}</b>
                  <span>Зона {s.row}</span>
                </button>
              ))}
            </div>
          </div>
        )}
      </div>
    </Card>
  )
}

export function RoutePanel({ spot, phase }: { spot?: Spot; phase: Phase }) {
  return (
    <Card title="Как проехать" className="card--route">
      {spot && phase === "done" ? (
        <ol className="route-steps">
          {routeSteps(spot).map((s, i) => (
            <li key={s.title} className={i === 2 ? "is-final" : ""}>
              <span className="route-steps__num">
                {i === 2 ? <Icon name="pin" size={13} /> : i + 1}
              </span>
              <div>
                <b>{s.title}</b>
                <small>{s.text}</small>
              </div>
            </li>
          ))}
        </ol>
      ) : (
        <p className="route-empty">
          <Icon name="route" size={16} />{" "}
          {phase === "done"
            ? "Для выбранных условий маршрут не найден."
            : "Выберите автомобиль, чтобы увидеть маршрут."}
        </p>
      )}
    </Card>
  )
}


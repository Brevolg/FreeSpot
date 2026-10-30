import { useMemo, useState } from "react"
import { SPOTS, ROWS, rankSpots, type VehicleType, type Priority, type Row, type Options } from "./parking"
import { Icon } from "./ui"
import { ParkingMap, Legend, type MapMode } from "./ParkingMap"
import { VehiclePanel, AvailabilityPanel, RecommendationPanel, RoutePanel, type Phase } from "./Panels"

export default function App() {
  const [vehicle, setVehicle] = useState<VehicleType | null>(null)
  const [charging, setCharging] = useState(false)
  const [accessible, setAccessible] = useState(false)
  const [priority, setPriority] = useState<Priority>("lifts")
  const [selectedId, setSelectedId] = useState<string | null>(null)

  const phase: Phase = vehicle ? "done" : "idle"
  const options: Options | null = vehicle
    ? { vehicle, charging, accessible, priority }
    : null
  const ranked = useMemo(
    () => (options ? rankSpots(options) : []),
    [vehicle, charging, accessible, priority],
  )
  const suitableIds = useMemo(() => new Set(ranked.map((s) => s.id)), [ranked])
  const rankOf = useMemo(
    () => new Map(ranked.map((s, i) => [s.id, i + 1])),
    [ranked],
  )
  const selected =
    phase === "done"
      ? (ranked.find((s) => s.id === selectedId) ?? ranked[0])
      : undefined

  const reset = () => {
    setVehicle(null)
    setAccessible(false)
    setCharging(false)
    setSelectedId(null)
  }

  const mapMode: MapMode = phase
  const alternatives = selected
    ? ranked.slice(0, 4).filter((s) => s.id !== selected.id)
    : []
  const stateClass =
    phase === "done" ? (selected ? "is-result" : "is-empty") : "is-idle"

  const zoneFree = (z: Row) =>
    SPOTS.filter((s) => s.row === z && !s.busy).length

  return (
    <div className="shell">
      <div className={`app ${stateClass}`}>
        <header className="topbar">
          <div className="brand">
            <span className="brand__mark">P</span>
            <div>
              <b>Парковка</b>
              <span>Подбор свободного места</span>
            </div>
          </div>
          <div className="topbar__center">
            <span className="place">
              <b>Обзор парковки</b>
              <span>Уровень P1</span>
              <span>40 мест</span>
            </span>
          </div>
        </header>

        <div className="board">
          <div className="board__main">
            <section className="card card--map">
              <header className="card__head">
                <div>
                  <h2>Схема парковки</h2>
                  <p className="card__sub">
                    {selected
                      ? `Выбрано место ${selected.id}`
                      : phase === "done"
                        ? "Подходящих мест нет"
                        : "Выберите тип автомобиля справа"}
                  </p>
                </div>
                <div className="zones" aria-label="Свободные места по зонам">
                  {ROWS.map((z) => (
                    <span
                      key={z}
                      className={`zone ${
                        selected?.row === z ? "is-active" : ""
                      }`}
                    >
                      Зона {z}
                      <b>{zoneFree(z)}</b>
                    </span>
                  ))}
                </div>
              </header>
              <div className="card--map__body">
                <ParkingMap
                  mode={mapMode}
                  selected={selected}
                  alternatives={alternatives}
                  rankOf={rankOf}
                  suitableIds={suitableIds}
                  onPick={(s) => setSelectedId(s.id)}
                />
              </div>
              <Legend />
            </section>
            <RoutePanel spot={selected} phase={phase} />
          </div>

          <aside className="board__side">
            <VehiclePanel
              vehicle={vehicle}
              onVehicle={(v) => {
                setVehicle(v)
                setSelectedId(null)
              }}
              charging={charging}
              setCharging={(v) => {
                setCharging(v)
                setSelectedId(null)
              }}
              accessible={accessible}
              setAccessible={(v) => {
                setAccessible(v)
                setSelectedId(null)
              }}
              priority={priority}
              setPriority={(v) => {
                setPriority(v)
                setSelectedId(null)
              }}
              onReset={reset}
            />
            <RecommendationPanel
              options={options}
              spot={selected}
              ranked={ranked}
              onPick={(s) => setSelectedId(s.id)}
              onWithoutCharging={() => {
                setCharging(false)
                setSelectedId(null)
              }}
              onWithoutAccessible={() => {
                setAccessible(false)
                setSelectedId(null)
              }}
              onReset={reset}
            />
            <AvailabilityPanel fitCount={options ? ranked.length : null} />
          </aside>
        </div>
      </div>
    </div>
  )
}

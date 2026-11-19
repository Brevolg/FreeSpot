import { useEffect, useMemo, useState } from "react"
import { ROWS, type VehicleType, type Priority, type Row, type Options, type Spot } from "./parking"
import { recommend, useParkingSpots } from "./api"
import { Icon } from "./ui"
import { ParkingMap, Legend, type MapMode } from "./ParkingMap"
import { VehiclePanel, AvailabilityPanel, RecommendationPanel, RoutePanel, type Phase } from "./Panels"
import { HomePage } from "./HomePage"

export default function App() {
  const [started, setStarted] = useState(false)
  const [vehicle, setVehicle] = useState<VehicleType | null>(null)
  const [charging, setCharging] = useState(false)
  const [accessible, setAccessible] = useState(false)
  const [priority, setPriority] = useState<Priority>("entry")
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [activeZone, setActiveZone] = useState<Row | null>(null)

  const { spots, loaded, error } = useParkingSpots()
  const [reco, setReco] = useState<{ key: string; ids: string[] } | null>(null)

  const options: Options | null = vehicle
    ? { vehicle, charging, accessible, priority }
    : null
  const optionsKey = options ? JSON.stringify(options) : ""
  // при каждом обновлении занятости пересчитываем подбор
  const occupancyKey = spots.map((s) => (s.busy ? 1 : 0)).join("")

  useEffect(() => {
    if (!options) return
    const ctrl = new AbortController()
    recommend(options, ctrl.signal)
      .then((ids) => setReco({ key: optionsKey, ids }))
      .catch(() => {})
    return () => ctrl.abort()
  }, [optionsKey, occupancyKey])

  const phase: Phase = options && reco?.key === optionsKey ? "done" : "idle"
  const ranked = useMemo(() => {
    if (phase !== "done" || !reco) return []
    const byId = new Map(spots.map((s) => [s.id, s]))
    return reco.ids.map((id) => byId.get(id)).filter((s): s is Spot => !!s)
  }, [phase, reco, spots])
  const zoneRanked = useMemo(
    () => (activeZone ? ranked.filter((s) => s.row === activeZone) : ranked),
    [ranked, activeZone],
  )
  const suitableIds = useMemo(() => new Set(zoneRanked.map((s) => s.id)), [zoneRanked])
  const rankOf = useMemo(
    () => new Map(zoneRanked.map((s, i) => [s.id, i + 1])),
    [zoneRanked],
  )
  const selected =
    phase === "done"
      ? (zoneRanked.find((s) => s.id === selectedId) ?? zoneRanked[0])
      : undefined

  const reset = () => {
    setVehicle(null)
    setAccessible(false)
    setCharging(false)
    setSelectedId(null)
  }

  const mapMode: MapMode = phase
  const alternatives = selected
    ? zoneRanked.slice(0, 4).filter((s) => s.id !== selected.id)
    : []
  const stateClass =
    phase === "done" ? (selected ? "is-result" : "is-empty") : "is-idle"

  const zoneFree = (z: Row) =>
    phase === "done"
      ? ranked.filter((s) => s.row === z).length
      : spots.filter((s) => s.row === z && !s.busy).length

  if (!started) {
    return (
      <HomePage
        spots={spots}
        loaded={loaded}
        onFind={() => setStarted(true)}
        onMap={() => setStarted(true)}
      />
    )
  }

  return (
    <div className="shell">
      <div className={`app ${stateClass}`}>
        <header className="topbar">
          <div className="brand">
            <span className="brand__mark">P</span>
            <div>
              <b>FreeSpot</b>
              <span>Подбор свободного места</span>
            </div>
          </div>
          <div className="topbar__center">
            <span className="place">
              <b>Обзор парковки</b>
              <span>Уровень P1</span>
              <span>{spots.length} мест</span>
              {error && <span role="status">нет связи с сервером</span>}
            </span>
          </div>
          <button className="home-link" type="button" onClick={() => setStarted(false)}>
            На главную
          </button>
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
                <div className="zones" role="group" aria-label="Фильтр по зонам">
                  {ROWS.map((z) => (
                    <button
                      key={z}
                      className={`zone ${
                        (activeZone ?? selected?.row) === z ? "is-active" : ""
                      }`}
                      type="button"
                      aria-pressed={activeZone === z || (!activeZone && selected?.row === z)}
                      onClick={() => {
                        setActiveZone((current) => (current === z ? null : z))
                        setSelectedId(null)
                      }}
                    >
                      Зона {z}
                      <b>{zoneFree(z)}</b>
                    </button>
                  ))}
                </div>
              </header>
              <div className="card--map__body">
                <ParkingMap
                  spots={spots}
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
              ranked={zoneRanked}
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
            <AvailabilityPanel
              spots={spots}
              fitCount={phase === "done" ? zoneRanked.length : null}
            />
          </aside>
        </div>
      </div>
    </div>
  )
}

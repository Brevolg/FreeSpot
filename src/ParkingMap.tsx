import { useEffect, useRef } from "react"
import { Icon, ICONS, type IconName } from "./ui"
import { SPOTS, ROWS, CELL_W, CELL_H, ROW_TOP, NOSE_DOWN, cellX, cellCx, routePath, type Row, type Spot } from "./parking"

const CAR_COLORS = [
  { body: "#f4f5f6", roof: "#e6e8eb" },
  { body: "#d5d9dd", roof: "#c4c9ce" },
  { body: "#4b5159", roof: "#3d434a" },
  { body: "#ece5d6", roof: "#ddd5c4" },
  { body: "#f4f5f6", roof: "#e6e8eb" },
]

/** Автомобиль, вид сверху. Нос смотрит вверх, размер 42×80. */
function TopCar({
  x,
  y,
  flip,
  tone,
}: {
  x: number
  y: number
  flip: boolean
  tone: number
}) {
  const c = CAR_COLORS[tone % CAR_COLORS.length]
  return (
    <g
      transform={`translate(${x} ${y})${flip ? " rotate(180 21 40)" : ""}`}
      filter="url(#car-shadow)"
    >
      <rect
        x="3"
        y="5"
        width="36"
        height="76"
        rx="13"
        fill="#1d2228"
        opacity="0.13"
      />
      <rect x="1" y="16" width="5" height="8" rx="2" fill={c.roof} />
      <rect x="36" y="16" width="5" height="8" rx="2" fill={c.roof} />
      <rect
        x="3"
        y="1"
        width="36"
        height="77"
        rx="13"
        fill={c.body}
        stroke="#bfc4ca"
        strokeWidth="1"
      />
      <path
        d="M8 12 Q9 5 14 4 M34 12 Q33 5 28 4 M8 71 Q9 76 15 76 M34 71 Q33 76 27 76"
        stroke="#fff"
        strokeWidth="1.8"
        strokeLinecap="round"
        opacity="0.7"
        fill="none"
      />
      <path d="M8 22 Q21 15 34 22 L32 34 Q21 30.5 10 34 Z" fill="#2a2f36" />
      <rect x="10" y="35" width="22" height="22" rx="4" fill={c.roof} stroke="#aab0b5" strokeWidth="0.7" />
      <path d="M11 36 L12 55 M31 36 L30 55" stroke="#fff" strokeWidth="1" opacity="0.6" />
      <path d="M10 59 Q21 62 32 59 L33.5 67 Q21 71.5 8.5 67 Z" fill="#2a2f36" />
      <path
        d="M9 5 h6 M27 5 h6"
        stroke="#f6e7a6"
        strokeWidth="2.2"
        strokeLinecap="round"
      />
    </g>
  )
}

function SvgIcon({
  name,
  x,
  y,
  size,
  color,
}: {
  name: IconName
  x: number
  y: number
  size: number
  color: string
}) {
  return (
    <svg
      x={x}
      y={y}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke={color}
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      {ICONS[name]}
    </svg>
  )
}

export type MapMode = "idle" | "done"

function MapCell({
  spot,
  mode,
  selected,
  altRank,
  suitable,
  onPick,
}: {
  spot: Spot
  mode: MapMode
  selected: boolean
  altRank: number
  suitable: boolean
  onPick: () => void
}) {
  const x = cellX(spot)
  const y = ROW_TOP[spot.row]
  const cx = x + CELL_W / 2
  const marker = spot.ev
    ? "bolt"
    : spot.size === "accessible"
      ? "wheelchair"
      : spot.size === "large"
        ? "xl"
        : null

  let kind: "busy" | "free" | "dim" | "selected" | "alt" = spot.busy
    ? "busy"
    : "free"
  if (selected) kind = "selected"
  else if (altRank) kind = "alt"
  else if (mode === "done" && !spot.busy && !suitable) kind = "dim"

  const label = {
    busy: "занято",
    free: "свободно",
    dim: "свободно, не подходит",
    selected: "выбранное место",
    alt: `вариант ${altRank}`,
  }[kind]
  const clickable = kind === "alt"

  return (
    <g
      className={`cell cell--${kind}`}
      role={clickable ? "button" : "img"}
      tabIndex={clickable ? 0 : undefined}
      aria-label={`Место ${spot.id}: ${label}`}
      onClick={clickable ? onPick : undefined}
      onKeyDown={
        clickable
          ? (e) => (e.key === "Enter" || e.key === " ") && onPick()
          : undefined
      }
    >
      <rect
        className="cell__hit"
        x={x + 4}
        y={y + 4}
        width={CELL_W - 8}
        height={CELL_H - 8}
        rx="10"
      />
      {kind === "busy" && (
        <TopCar
          x={cx - 21}
          y={y + 15}
          flip={NOSE_DOWN[spot.row]}
          tone={spot.index + spot.row.charCodeAt(0)}
        />
      )}
      {(kind === "free" || kind === "dim" || kind === "alt") && (
        <>
          <text className="cell__id" x={cx} y={y + 58} textAnchor="middle">
            {spot.id}
          </text>
          <text className="cell__label" x={cx} y={y + 78} textAnchor="middle">
            {kind === "alt" ? `Вариант ${altRank}` : "свободно"}
          </text>
        </>
      )}
      {kind === "selected" && (
        <>
          <circle cx={cx} cy={y + 38} r="15" className="cell__pin" />
          <SvgIcon name="pin" x={cx - 9} y={y + 29} size={18} color="#1d2126" />
          <text
            className="cell__id cell__id--selected"
            x={cx}
            y={y + 76}
            textAnchor="middle"
          >
            {spot.id}
          </text>
          <text
            className="cell__label cell__label--selected"
            x={cx}
            y={y + 94}
            textAnchor="middle"
          >
            ваше место
          </text>
        </>
      )}
      {kind === "alt" && (
        <g className="cell__rank">
          <circle cx={x + 16} cy={y + 18} r="9" />
          <text x={x + 16} y={y + 22} textAnchor="middle">
            {altRank}
          </text>
        </g>
      )}
      {marker && kind !== "selected" && (
        <g className={`cell__marker cell__marker--${marker}`}>
          <circle cx={x + CELL_W - 15} cy={y + 18} r="9" />
          {marker === "xl" ? (
            <text x={x + CELL_W - 15} y={y + 21.5} textAnchor="middle">
              XL
            </text>
          ) : (
            <SvgIcon
              name={marker}
              x={x + CELL_W - 21}
              y={y + 12}
              size={12}
              color="currentColor"
            />
          )}
        </g>
      )}
    </g>
  )
}

export function ParkingMap({
  mode,
  selected,
  alternatives,
  rankOf,
  suitableIds,
  onPick,
}: {
  mode: MapMode
  selected?: Spot
  alternatives: Spot[]
  rankOf: Map<string, number>
  suitableIds: Set<string>
  onPick: (s: Spot) => void
}) {
  const scrollRef = useRef<HTMLDivElement>(null)

  // На телефоне схема прокручивается — подводим выбранное место к центру.
  useEffect(() => {
    const el = scrollRef.current
    if (!el || !selected || el.scrollWidth <= el.clientWidth) return
    const ratio = cellCx(selected) / 1000
    el.scrollTo({
      left: ratio * el.scrollWidth - el.clientWidth / 2,
      behavior: "smooth",
    })
  }, [selected])

  const rowLines = (row: Row) => {
    const top = ROW_TOP[row]
    const back = NOSE_DOWN[row] ? top : top + CELL_H
    return (
      <g key={row} className="map__lines">
        <line x1="100" y1={back} x2="900" y2={back} />
        {Array.from({ length: 11 }, (_, k) => (
          <line
            key={k}
            x1={100 + k * CELL_W}
            y1={top}
            x2={100 + k * CELL_W}
            y2={top + CELL_H}
          />
        ))}
      </g>
    )
  }

  return (
    <div className={`map map--${mode}`} ref={scrollRef}>
      <svg
        className="map__svg"
        viewBox="0 0 1000 640"
        role="group"
        aria-label="Схема парковки, уровень P1"
      >
        <defs>
          <filter id="car-shadow" x="-30%" y="-20%" width="160%" height="150%">
            <feDropShadow dx="1.5" dy="3.5" stdDeviation="3" floodColor="#343c42" floodOpacity="0.25" />
          </filter>
          <marker
            id="route-head"
            viewBox="0 0 10 10"
            refX="5"
            refY="5"
            markerWidth="3.2"
            markerHeight="3.2"
            orient="auto"
          >
            <path d="M0 0 10 5 0 10Z" fill="#1d2126" />
          </marker>
        </defs>

        {/* Проезды */}
        <rect
          x="0"
          y="0"
          width="90"
          height="640"
          rx="14"
          className="map__aisle"
        />
        <rect x="0" y="130" width="1000" height="80" className="map__aisle" />
        <rect x="0" y="430" width="1000" height="80" className="map__aisle" />
        <rect
          x="900"
          y="130"
          width="100"
          height="510"
          rx="14"
          className="map__aisle"
        />
        <path
          d="M 45 60 V 600 M 110 170 H 890 M 110 470 H 890"
          className="map__lane"
        />
        {[220, 340].map((y) => (
          <path key={y} d={`M 38 ${y} l 7 9 7 -9`} className="map__flow" />
        ))}
        {[300, 560, 780].map((x) => (
          <path key={x} d={`M ${x} 163 l 9 7 -9 7`} className="map__flow" />
        ))}
        {[300, 560, 780].map((x) => (
          <path
            key={`b${x}`}
            d={`M ${x} 463 l 9 7 -9 7`}
            className="map__flow"
          />
        ))}
        <text x="110" y="200" className="map__aisle-label">
          Проезд 1
        </text>
        <text x="110" y="500" className="map__aisle-label">
          Проезд 2
        </text>

        {ROWS.map(rowLines)}

        <g className="map__gate">
          <rect x="8" y="8" width="74" height="34" rx="17" />
          <text x="38" y="30" textAnchor="middle">
            Въезд
          </text>
          <path d="M 62 19 v 12 M 57 26 l 5 5 5 -5" />
        </g>
        <g className="map__gate map__gate--out">
          <rect x="8" y="598" width="74" height="34" rx="17" />
          <text x="38" y="620" textAnchor="middle">
            Выезд
          </text>
        </g>

        <g className="map__lifts">
          <rect x="910" y="24" width="80" height="100" rx="14" />
          <SvgIcon name="lift" x={938} y={40} size={24} color="#1d2126" />
          <text x="950" y="88" textAnchor="middle">
            Лифты
          </text>
          <text x="950" y="105" textAnchor="middle" className="map__lifts-sub">
            выход
          </text>
        </g>

        {([
          ["B", 270],
          ["C", 380],
          ["D", 570],
        ] as const).map(([z, y]) => (
          <text key={z} x="950" y={y} textAnchor="middle" className="map__zone">
            Зона {z}
          </text>
        ))}

        {mode === "done" && selected && (
          <g key={selected.id} className="map__route">
            <path d={routePath(selected)} className="map__route-casing" />
            <path
              d={routePath(selected)}
              className="map__route-line"
              markerEnd="url(#route-head)"
            />
          </g>
        )}

        {SPOTS.map((s) => (
          <MapCell
            key={s.id}
            spot={s}
            mode={mode}
            selected={selected?.id === s.id}
            altRank={
              alternatives.some((a) => a.id === s.id)
                ? (rankOf.get(s.id) ?? 0)
                : 0
            }
            suitable={suitableIds.has(s.id)}
            onPick={() => onPick(s)}
          />
        ))}
      </svg>
    </div>
  )
}

export function Legend() {
  return (
    <div className="legend" aria-label="Обозначения">
      <span>
        <i className="lg lg--free">A1</i>Свободно
      </span>
      <span>
        <i className="lg lg--busy">
          <svg viewBox="0 0 42 80" width="9" height="17">
            <rect
              x="3"
              y="1"
              width="36"
              height="77"
              rx="13"
              fill="#d5d9dd"
              stroke="#9aa1a9"
            />
            <path
              d="M8 22 Q21 15 34 22 L32 34 Q21 30.5 10 34 Z"
              fill="#2a2f36"
            />
          </svg>
        </i>
        Занято
      </span>
      <span>
        <i className="lg lg--selected">
          <Icon name="pin" size={12} />
        </i>
        Ваше место
      </span>
      <span>
        <i className="lg lg--alt">2</i>Вариант
      </span>
      <span>
        <i className="lg lg--route" />
        Маршрут
      </span>
      <span className="legend__sep" />
      <span>
        <i className="mk mk--bolt">
          <Icon name="bolt" size={10} />
        </i>
        Зарядка
      </span>
      <span>
        <i className="mk mk--wheelchair">
          <Icon name="wheelchair" size={10} />
        </i>
        Маломобильным
      </span>
      <span>
        <i className="mk mk--xl">XL</i>Широкое
      </span>
    </div>
  )
}


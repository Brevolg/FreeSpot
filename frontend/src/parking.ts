export type VehicleType = "compact" | "sedan" | "suv" | "electric"
export type Priority = "lifts" | "entry"
export type Row = "A" | "B" | "C" | "D"
export type SpotSize = "compact" | "standard" | "large" | "accessible"

export interface Spot {
  id: string
  row: Row
  index: number
  size: SpotSize
  ev: boolean
  busy: boolean
}

export interface Options {
  vehicle: VehicleType
  charging: boolean
  accessible: boolean
  priority: Priority
}

export const ROWS: Row[] = ["A", "B", "C", "D"]

function sizeFor(row: Row, i: number): SpotSize {
  if (row === "A" && i >= 8) return "accessible"
  if (row === "B" && i < 3) return "compact"
  if (row === "D" && i >= 6) return "large"
  return "standard"
}

// План уровня P1. Занятость (busy) приходит с бэкенда — см. api.ts
export const SPOTS: Spot[] = ROWS.flatMap((row) =>
  Array.from({ length: 10 }, (_, i) => {
    const id = `${row}${String(i + 1).padStart(2, "0")}`
    return {
      id,
      row,
      index: i,
      size: sizeFor(row, i),
      ev: row === "C" && i < 4,
      busy: false,
    }
  }),
)

export const SIZE_INFO: Record<SpotSize, { label: string; dims: string }> = {
  compact: { label: "Компактное", dims: "2,3 × 4,5 м" },
  standard: { label: "Стандартное", dims: "2,5 × 5,0 м" },
  large: { label: "Широкое", dims: "2,8 × 5,5 м" },
  accessible: { label: "Для маломобильных", dims: "3,5 × 5,0 м" },
}

export const ZONE_INFO: Record<Row, string> = {
  A: "у лифтов",
  B: "центр",
  C: "зарядка",
  D: "широкие места",
}

export const VEHICLES: Array<{ id: VehicleType; label: string; dims: string }> = [
  { id: "compact", label: "Компактный", dims: "до 4,2 м" },
  { id: "sedan", label: "Седан", dims: "до 4,9 м" },
  { id: "suv", label: "Внедорожник", dims: "до 5,3 м" },
  { id: "electric", label: "Электромобиль", dims: "до 4,9 м" },
]

export const CELL_W = 80
export const CELL_H = 110
export const ROW_TOP: Record<Row, number> = { A: 20, B: 210, C: 320, D: 510 }
const AISLE_Y: Record<Row, number> = { A: 170, B: 170, C: 470, D: 470 }
export const NOSE_DOWN: Record<Row, boolean> = {
  A: true,
  B: false,
  C: true,
  D: false,
}

export const cellX = (s: Spot) => 100 + s.index * CELL_W
export const cellCx = (s: Spot) => cellX(s) + CELL_W / 2

export function routePath(s: Spot) {
  const end = { A: 122, B: 218, C: 422, D: 518 }[s.row]
  return `M 45 42 V ${AISLE_Y[s.row]} H ${cellCx(s)} V ${end}`
}

export function reasonsFor(s: Spot, o: Options, isBest: boolean) {
  const list: string[] = []
  const sizeLabel = s.size === "accessible" ? "Расширенное место" : `${SIZE_INFO[s.size].label} место`
  list.push(`${sizeLabel} подходит по размеру.`)
  if (s.ev && o.charging) list.push("На месте есть зарядка.")
  if (isBest)
    list.push(
      o.priority === "lifts"
        ? "При подборе учтена близость к лифтам"
        : "При подборе учтён путь от въезда",
    )
  return list
}

export function routeSteps(s: Spot) {
  const aisle = s.row === "A" || s.row === "B" ? 1 : 2
  const side = s.row === "A" || s.row === "C" ? "слева" : "справа"
  return [
    { title: "Въезд", text: `Следуйте до проезда ${aisle}` },
    { title: `Ряд ${s.row}`, text: `Двигайтесь вдоль проезда ${aisle}` },
    { title: `Место ${s.id}`, text: `Будет ${side} по ходу движения` },
  ]
}

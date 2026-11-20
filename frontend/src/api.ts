import { useEffect, useState } from "react"
import { SPOTS, type Options, type Spot } from "./parking"

const BASE = import.meta.env.VITE_API_URL ?? import.meta.env.BASE_URL.replace(/\/$/, "")
const POLL_MS = 5000

interface ApiSpot {
  id: string
  busy: boolean
}

interface ApiRecommendation {
  spots: Array<{ rank: number; spot: ApiSpot }>
  no_fit_reason: string | null
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    ...init,
    headers: { "Content-Type": "application/json", ...init?.headers },
  })
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`)
  return res.json() as Promise<T>
}

/** Текущая занятость: план парковки из parking.ts + busy с бэкенда. Обновляется каждые 5 секунд. */
export function useParkingSpots() {
  const [spots, setSpots] = useState<Spot[]>(SPOTS)
  const [loaded, setLoaded] = useState(false)
  const [error, setError] = useState(false)

  useEffect(() => {
    let alive = true
    const load = async () => {
      try {
        const data = await request<ApiSpot[]>("/api/spots")
        const busy = new Map(data.map((s) => [s.id, s.busy]))
        if (!alive) return
        setSpots(SPOTS.map((s) => ({ ...s, busy: busy.get(s.id) ?? true })))
        setLoaded(true)
        setError(false)
      } catch {
        if (alive) setError(true)
      }
    }
    load()
    const timer = setInterval(load, POLL_MS)
    return () => {
      alive = false
      clearInterval(timer)
    }
  }, [])

  return { spots, loaded, error }
}

/** Подбор мест на бэкенде: возвращает id мест в порядке рекомендации. */
export async function recommend(o: Options, signal?: AbortSignal): Promise<string[]> {
  const data = await request<ApiRecommendation>("/api/recommendations", {
    method: "POST",
    body: JSON.stringify(o),
    signal,
  })
  return data.spots.map((s) => s.spot.id)
}

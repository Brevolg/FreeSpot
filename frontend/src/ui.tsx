import type { ReactNode } from "react"

export type IconName = "bolt" | "check" | "compact" | "electric" | "lift" | "pin" | "route" | "search" | "sedan" | "suv" | "walk" | "wheelchair" | "x" | "reset"

export const ICONS: Record<IconName, ReactNode> = {
  bolt: <path d="M13 2 5 14h6l-1 8 8-12h-6l1-8Z" />,
  check: <path d="m5 12.5 4.5 4.5L19 7.5" />,
  compact: (
    <>
      <path d="M5 16v-3l2.5-4.5h6.5l3.5 4.5H19v3" />
      <circle cx="8" cy="16.5" r="1.8" />
      <circle cx="16" cy="16.5" r="1.8" />
    </>
  ),
  sedan: (
    <>
      <path d="M2.5 16v-2.5l3.5-1.5 3-4h7l3 4 2.5 1v3" />
      <circle cx="7" cy="16.5" r="1.8" />
      <circle cx="17" cy="16.5" r="1.8" />
    </>
  ),
  suv: (
    <>
      <path d="M2.5 16V9l2-3h11l3.5 4h2.5v6" />
      <path d="M2.5 11h19" />
      <circle cx="7" cy="16.5" r="1.9" />
      <circle cx="17" cy="16.5" r="1.9" />
    </>
  ),
  electric: (
    <>
      <path d="M2.5 16v-2.5l3.5-1.5 3-4h7l3 4 2.5 1v3" />
      <circle cx="7" cy="16.5" r="1.8" />
      <circle cx="17" cy="16.5" r="1.8" />
      <path d="m12.5 9.5-1.5 2.5h2l-1.5 2.5" />
    </>
  ),
  lift: (
    <>
      <rect x="4" y="3" width="16" height="18" rx="2" />
      <path d="M12 3v18M7.5 10l1.5-2 1.5 2M13.5 14l1.5 2 1.5-2" />
    </>
  ),
  pin: (
    <>
      <path d="M19 10c0 5-7 11-7 11s-7-6-7-11a7 7 0 1 1 14 0Z" />
      <circle cx="12" cy="10" r="2.5" />
    </>
  ),
  reset: (
    <>
      <path d="M4 11a8 8 0 1 1 2.3 5.7M4 4v7h7" />
    </>
  ),
  route: (
    <>
      <circle cx="6" cy="19" r="2" />
      <circle cx="18" cy="5" r="2" />
      <path d="M8 19h4a3 3 0 0 0 3-3V8a3 3 0 0 1 3-3" />
    </>
  ),
  search: (
    <>
      <circle cx="11" cy="11" r="6.5" />
      <path d="m20 20-4.2-4.2" />
    </>
  ),
  walk: (
    <>
      <circle cx="13" cy="4.5" r="1.8" />
      <path d="m9 21 2.5-6 2.5 2.5V21M8 11l3-3.5h3l2 4 2.5 1M11.5 15l1-6" />
    </>
  ),
  wheelchair: (
    <>
      <circle cx="11" cy="4.5" r="1.8" />
      <path d="M11 7.5V13h5l2 5M11 10H8M8.5 11.5a5 5 0 1 0 6.5 6" />
    </>
  ),
  x: <path d="M7 7l10 10M17 7 7 17" />,
}

export function Icon({
  name,
  size = 20,
  className,
}: {
  name: IconName
  size?: number
  className?: string
}) {
  return (
    <svg
      className={className}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      {ICONS[name]}
    </svg>
  )
}

export function Button({
  children,
  variant = "accent",
  onClick,
  disabled,
  className = "",
}: {
  children: ReactNode
  variant?: "accent" | "soft"
  onClick?: () => void
  disabled?: boolean
  className?: string
}) {
  return (
    <button
      type="button"
      className={`btn btn--${variant} ${className}`}
      onClick={onClick}
      disabled={disabled}
    >
      {children}
    </button>
  )
}

export function Card({
  title,
  action,
  children,
  className = "",
}: {
  title: string
  action?: ReactNode
  children: ReactNode
  className?: string
}) {
  return (
    <section className={`card ${className}`}>
      <header className="card__head">
        <h2>{title}</h2>
        {action}
      </header>
      {children}
    </section>
  )
}

export function ToggleChip({
  checked,
  onChange,
  icon,
  children,
}: {
  checked: boolean
  onChange: () => void
  icon: IconName
  children: ReactNode
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      className={`chip ${checked ? "is-on" : ""}`}
      onClick={onChange}
    >
      <Icon name={icon} size={15} />
      {children}
      <span className="chip__box" aria-hidden="true">
        {checked && <Icon name="check" size={11} />}
      </span>
    </button>
  )
}


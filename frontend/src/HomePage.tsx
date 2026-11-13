import { SPOTS, ROWS } from "./parking"
import { Icon } from "./ui"

const freeSpots = SPOTS.filter((spot) => !spot.busy)

export function HomePage({ onFind, onMap }: { onFind: () => void; onMap: () => void }) {
  return (
    <main className="home-shell">
      <div className="home-page">
        <header className="home-header">
          <a className="home-brand" href="#top" aria-label="Парковка — главная">
            <span className="home-brand__mark"><Icon name="pin" size={19} /></span>
            <span><b>FreeSpot</b><small>умный подбор места</small></span>
          </a>
          <div className="home-location">
            <span className="home-location__icon"><Icon name="pin" size={16} /></span>
            <span><small>Текущая парковка</small><b>Паркинг · уровень P1</b></span>
            <span className="home-location__chevron">⌄</span>
          </div>
        </header>

        <section className="home-hero" id="top">
          <div className="home-hero__copy">
            <h1 className="home-hero__headline">
              <span className="home-hero__title-font">ПАРКУЙТЕСЬ С УМОМ</span>
              <span className="home-hero__title-sub">без лишних кругов</span>
            </h1>
            <p className="home-lead">
              Подберём место, которое подходит вашему автомобилю, и покажем удобный путь от въезда
            </p>
            <div className="home-trust">
              <span><Icon name="check" size={15} /> По размеру автомобиля</span>
              <span><Icon name="check" size={15} /> С учётом занятости</span>
            </div>
            <div className="home-actions">
              <button className="home-cta" type="button" onClick={onFind}>
                Найти подходящее место
              </button>
            </div>
          </div>

          <aside className="home-preview" aria-label="Занятость парковки">
            <div className="home-preview__top">
              <div>
                <span className="home-preview__label">Сейчас на парковке:</span>
              </div>
            </div>
            <div className="home-free-count">
              <strong>{freeSpots.length.toString().padStart(2, "0")}</strong>
              <span><b>свободных мест</b><small>из {SPOTS.length} на уровне P1</small></span>
            </div>
            <div className="home-occupancy">
              <div><span>Занятость парковки</span><b>{SPOTS.length - freeSpots.length} / {SPOTS.length}</b></div>
              <span className="home-occupancy__bar"><i style={{ width: `${((SPOTS.length - freeSpots.length) / SPOTS.length) * 100}%` }} /></span>
            </div>
            <div className="home-map-preview" aria-label="Обзор свободных и занятых мест по зонам">
              <div className="home-map-preview__entry"><span /> ВЪЕЗД</div>
              <div className="home-mini-rows">
                {ROWS.map((row) => {
                  const rowSpots = SPOTS.filter((spot) => spot.row === row)
                  const rowFree = rowSpots.filter((spot) => !spot.busy).length
                  return (
                    <div className="home-mini-row" key={row}>
                      <b>{row}</b>
                      <div className="home-mini-row__slots">
                        {rowSpots.map((spot) => <i key={spot.id} className={spot.busy ? "is-busy" : "is-free"} />)}
                      </div>
                      <small>{rowFree} свободно</small>
                    </div>
                  )
                })}
              </div>
              <div className="home-map-preview__legend"><span><i className="is-free" /> Свободно</span><span><i className="is-busy" /> Занято</span></div>
            </div>
            <button className="home-preview__link" type="button" onClick={onMap}>Открыть всю схему <span>→</span></button>
          </aside>
        </section>

        <section className="home-benefits" aria-label="Возможности сервиса">
          <article><span className="home-benefit-icon"><Icon name="suv" size={19} /></span><span><b>Подходит вашему авто</b><small>Компактный, седан, внедорожник или электромобиль</small></span><span className="home-benefit-index"></span></article>
          <article><span className="home-benefit-icon"><Icon name="pin" size={19} /></span><span><b>Учитывает ваши условия</b><small>Зарядка, доступность и расстояние до лифта</small></span><span className="home-benefit-index"></span></article>
          <article><span className="home-benefit-icon"><Icon name="route" size={19} /></span><span><b>Ведёт прямо к месту</b><small>Понятный маршрут от въезда по парковке</small></span><span className="home-benefit-index"></span></article>
        </section>
      </div>
    </main>
  )
}

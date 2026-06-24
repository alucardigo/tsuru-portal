import { Controller } from "@hotwired/stimulus"

// Ticker: incrementa um display "HH:MM:SS" a cada segundo a partir de um epoch UTC.
//   <span data-controller="ticker" data-ticker-start-value="2026-06-24T14:30:00Z"></span>
export default class extends Controller {
  static values = { start: String }

  connect() {
    this.startedAt = Date.parse(this.startValue)
    this.tick()
    this.handle = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.handle)
  }

  tick() {
    const secs = Math.max(0, Math.floor((Date.now() - this.startedAt) / 1000))
    const h = String(Math.floor(secs / 3600)).padStart(2, "0")
    const m = String(Math.floor((secs % 3600) / 60)).padStart(2, "0")
    const s = String(secs % 60).padStart(2, "0")
    this.element.textContent = `${h}:${m}:${s}`
  }
}

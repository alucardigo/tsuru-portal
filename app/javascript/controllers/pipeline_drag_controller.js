import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Arraste de demandas entre fases do Pipeline. Cada drop dispara uma transição
// de estado válida no backend (POST /pipeline/:id/mover). Movimento inválido é
// recusado pelo servidor e o card volta ao lugar (reload).
export default class extends Controller {
  static targets = ["list"]
  static values  = { csrf: String }

  connect() {
    this.sortables = this.listTargets.map((list) => {
      const aceita = list.dataset.drop === "true"
      return Sortable.create(list, {
        group: { name: "pipeline", pull: true, put: aceita },
        sort: false, // ordem dentro da coluna não importa aqui
        animation: 150,
        ghostClass: "ring-2",
        chosenClass: "opacity-60",
        filter: "a, button, select, [data-no-drag]",
        preventOnFilter: false,
        onEnd: (evt) => this.persist(evt)
      })
    })
  }

  disconnect() {
    (this.sortables || []).forEach((s) => s.destroy())
    this.sortables = []
  }

  async persist(evt) {
    if (evt.to === evt.from) return // mesma coluna, nada a fazer
    const url = evt.item.dataset.moveUrl
    const etapa = evt.to.dataset.etapa
    if (!url || !etapa) return

    try {
      const resp = await fetch(url, {
        method: "POST",
        headers: {
          "X-CSRF-Token": this.csrfValue,
          "Accept": "application/json",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ etapa })
      })
      const data = await resp.json().catch(() => ({}))
      if (resp.ok && data.ok) {
        this.banner(true, `${data.codigo} avançou no fluxo.`)
        setTimeout(() => window.location.reload(), 650)
      } else {
        this.banner(false, data.message || "Movimento não permitido.")
        setTimeout(() => window.location.reload(), 1800) // reverte
      }
    } catch (_e) {
      window.location.reload()
    }
  }

  banner(ok, msg) {
    let el = document.getElementById("pipeline-banner")
    if (!el) {
      el = document.createElement("div")
      el.id = "pipeline-banner"
      el.style.cssText = "position:fixed;top:16px;left:50%;transform:translateX(-50%);z-index:9999;padding:10px 18px;border-radius:8px;font-size:13px;font-weight:500;box-shadow:0 4px 16px rgba(0,0,0,.15);"
      document.body.appendChild(el)
    }
    el.style.background = ok ? "#ecfdf5" : "#fef2f2"
    el.style.color = ok ? "#047857" : "#b91c1c"
    el.style.border = `1px solid ${ok ? "#a7f3d0" : "#fecaca"}`
    el.textContent = (ok ? "✓ " : "✕ ") + msg
  }
}

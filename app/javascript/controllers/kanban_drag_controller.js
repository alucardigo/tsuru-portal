import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Drag-and-drop dos cards do kanban via SortableJS (robusto, multi-coluna).
// Cada lista de coluna vira um Sortable do mesmo grupo; ao soltar, persiste via PATCH.
export default class extends Controller {
  static targets = ["list"]
  static values  = { csrf: String }

  connect() {
    this.sortables = this.listTargets.map((list) =>
      Sortable.create(list, {
        group: "kanban-tasks",
        animation: 150,
        ghostClass: "ring-2",
        chosenClass: "opacity-60",
        // não inicia arraste ao clicar em elementos interativos do card
        filter: "a, button, select, input, textarea, [data-no-drag]",
        preventOnFilter: false,
        onEnd: (evt) => this.persist(evt)
      })
    )
  }

  disconnect() {
    (this.sortables || []).forEach((s) => s.destroy())
    this.sortables = []
  }

  async persist(evt) {
    const card = evt.item
    const url = card.dataset.moveUrl
    const status = evt.to.dataset.status
    if (!url || !status) return

    try {
      const resp = await fetch(url, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": this.csrfValue,
          "Accept": "application/json",
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ kanban_status: status, position: evt.newIndex })
      })
      if (!resp.ok) {
        window.location.reload() // reverte para o estado do servidor
        return
      }
      this.refreshCounts()
    } catch (_e) {
      window.location.reload()
    }
  }

  // Atualiza os contadores no topo de cada coluna
  refreshCounts() {
    this.listTargets.forEach((list) => {
      const badge = list.parentElement.querySelector("[data-kanban-count]")
      if (badge) badge.textContent = list.querySelectorAll("[data-kanban-card]").length
    })
  }
}

import { Controller } from "@hotwired/stimulus"

// Drag-and-drop nativo HTML5 entre colunas do kanban interno do projeto.
// Backend recebe PATCH /demands/:demand_id/tasks/:id/move com kanban_status + position.
export default class extends Controller {
  static targets = ["column", "list", "card"]
  static values  = { moveUrl: String, csrf: String }

  connect() {
    this.cardTargets.forEach(card => this.wireCard(card))
    this.columnTargets.forEach(col => this.wireColumn(col))
  }

  wireCard(card) {
    card.addEventListener("dragstart", (e) => {
      this.draggedId = card.dataset.taskId
      card.classList.add("opacity-50")
      e.dataTransfer.effectAllowed = "move"
    })
    card.addEventListener("dragend", () => {
      card.classList.remove("opacity-50")
    })
  }

  wireColumn(column) {
    const list = column.querySelector("[data-kanban-drag-target='list']") || column

    column.addEventListener("dragover", (e) => {
      e.preventDefault()
      column.classList.add("ring-2", "ring-indigo-300")
    })
    column.addEventListener("dragleave", () => {
      column.classList.remove("ring-2", "ring-indigo-300")
    })
    column.addEventListener("drop", async (e) => {
      e.preventDefault()
      column.classList.remove("ring-2", "ring-indigo-300")
      if (!this.draggedId) return

      const status = column.dataset.status
      const position = list.children.length  // append no fim

      const url = this.moveUrlValue.replace(":id", this.draggedId)
      try {
        const r = await fetch(url, {
          method: "PATCH",
          headers: {
            "X-CSRF-Token": this.csrfValue,
            "Accept": "application/json",
            "Content-Type": "application/json"
          },
          body: JSON.stringify({ kanban_status: status, position })
        })
        if (r.ok) {
          window.location.reload()  // reload simples; futuramente Turbo Stream
        } else {
          console.error("Move failed", r.status)
        }
      } catch (err) {
        console.error(err)
      }
    })
  }
}

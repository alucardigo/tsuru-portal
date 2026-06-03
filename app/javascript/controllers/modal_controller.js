import { Controller } from "@hotwired/stimulus"

// Modal flutuante simples — clica no backdrop ou pressiona ESC pra fechar.
export default class extends Controller {
  static targets = ["dialog"]

  connect() {
    this.escListener = (e) => { if (e.key === "Escape") this.close() }
    document.addEventListener("keydown", this.escListener)
  }

  disconnect() {
    document.removeEventListener("keydown", this.escListener)
  }

  backdropClose(event) {
    if (!this.hasDialogTarget) return
    if (!this.dialogTarget.contains(event.target)) this.close()
  }

  close() {
    // Volta pra URL anterior se tiver, ou recarrega o kanban
    if (document.referrer) {
      window.location.href = document.referrer
    } else {
      window.history.back()
    }
  }
}

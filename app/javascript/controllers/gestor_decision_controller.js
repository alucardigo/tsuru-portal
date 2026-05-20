import { Controller } from "@hotwired/stimulus"

// Sincroniza o textarea de comentário para os 3 inputs hidden dos forms
// Encaminhar/Devolver/Arquivar antes do submit. Atualiza contador também.
export default class extends Controller {
  static targets = ["comentario", "counter"]

  connect() {
    this.updateCounter()
    this.comentarioTarget.addEventListener("input", () => this.updateCounter())

    this.element.querySelectorAll("form").forEach((form) => {
      form.addEventListener("submit", () => {
        const hidden = form.querySelector('input[name="comentario"]')
        if (hidden) hidden.value = this.comentarioTarget.value
      })
    })
  }

  updateCounter() {
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = this.comentarioTarget.value.length
    }
  }
}

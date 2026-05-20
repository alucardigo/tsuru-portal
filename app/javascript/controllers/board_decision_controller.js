import { Controller } from "@hotwired/stimulus"

// Sincroniza o texto da justificativa do textarea principal para todos os
// inputs hidden dos 3 forms (Aprovar / Adiar / Rejeitar) antes do submit.
// Também atualiza o contador de caracteres em tempo real.
export default class extends Controller {
  static targets = ["justification", "counter"]

  connect() {
    this.updateCounter()
    this.justificationTarget.addEventListener("input", () => this.updateCounter())

    // Antes de qualquer form button_to dentro deste controller fazer submit,
    // copiamos o texto para o input hidden name="justification" daquele form.
    this.element.querySelectorAll("form").forEach((form) => {
      form.addEventListener("submit", (e) => {
        const hidden = form.querySelector('input[name="justification"]')
        if (hidden) hidden.value = this.justificationTarget.value
      })
    })
  }

  updateCounter() {
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = this.justificationTarget.value.length
    }
  }
}

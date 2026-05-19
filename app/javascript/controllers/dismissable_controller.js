import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  dismiss() {
    this.element.remove()
  }

  connect() {
    setTimeout(() => this.element.remove(), 5000)
  }
}

import { Controller } from "@hotwired/stimulus"

// YesNo toggle for triagem N1 questions.
// Recolors the Sim/Não pills client-side when the user picks one,
// without waiting for a full page reload.
export default class extends Controller {
  static targets = ["sim", "nao", "simLabel", "naoLabel"]

  connect() {
    this.refresh()
  }

  refresh() {
    const simChecked = this.hasSimTarget && this.simTarget.checked
    const naoChecked = this.hasNaoTarget && this.naoTarget.checked

    if (this.hasSimLabelTarget) {
      this._apply(this.simLabelTarget, simChecked, ["bg-rose-600", "text-white"], ["text-gray-600", "hover:bg-white"])
    }
    if (this.hasNaoLabelTarget) {
      this._apply(this.naoLabelTarget, naoChecked, ["bg-emerald-600", "text-white"], ["text-gray-600", "hover:bg-white"])
    }
  }

  _apply(el, active, activeCls, idleCls) {
    if (active) {
      idleCls.forEach((c) => el.classList.remove(c))
      activeCls.forEach((c) => el.classList.add(c))
    } else {
      activeCls.forEach((c) => el.classList.remove(c))
      idleCls.forEach((c) => el.classList.add(c))
    }
  }
}

import { Controller } from "@hotwired/stimulus"

// Sidebar responsivo (mobile/tablet drawer off-canvas; desktop fixo)
// Markup esperado:
//   <div data-controller="sidebar">
//     <aside data-sidebar-target="panel" class="-translate-x-full lg:translate-x-0 ...">
//     <div   data-sidebar-target="backdrop" class="hidden lg:hidden">
//     <button data-action="click->sidebar#toggle">
export default class extends Controller {
  static targets = ["panel", "backdrop"]

  connect() {
    this._onResize = () => { if (window.innerWidth >= 1024) this.close() }
    this._onKey    = (e) => { if (e.key === "Escape") this.close() }
    this._onNavClick = (e) => {
      if (window.innerWidth >= 1024) return
      if (e.target.closest("a")) this.close()
    }
    window.addEventListener("resize", this._onResize)
    document.addEventListener("keydown", this._onKey)
    if (this.hasPanelTarget) this.panelTarget.addEventListener("click", this._onNavClick)
  }

  disconnect() {
    window.removeEventListener("resize", this._onResize)
    document.removeEventListener("keydown", this._onKey)
    if (this.hasPanelTarget) this.panelTarget.removeEventListener("click", this._onNavClick)
  }

  toggle() { this.isOpen() ? this.close() : this.open() }

  open() {
    if (!this.hasPanelTarget) return
    this.panelTarget.classList.remove("-translate-x-full")
    this.panelTarget.classList.add("translate-x-0")
    if (this.hasBackdropTarget) this.backdropTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden", "lg:overflow-auto")
  }

  close() {
    if (!this.hasPanelTarget) return
    this.panelTarget.classList.add("-translate-x-full")
    this.panelTarget.classList.remove("translate-x-0")
    if (this.hasBackdropTarget) this.backdropTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden", "lg:overflow-auto")
  }

  isOpen() {
    return this.hasPanelTarget && !this.panelTarget.classList.contains("-translate-x-full")
  }
}

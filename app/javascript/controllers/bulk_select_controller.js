import { Controller } from "@hotwired/stimulus"

// Sprint 28 — seleção em massa no kanban. Checkboxes nas cards alimentam a
// barra de ações (mudar status/prioridade/responsável ou excluir em lote).
export default class extends Controller {
  static targets = ["box", "bar", "count", "op", "value"]
  static values = { url: String, csrf: String }

  refresh() {
    const n = this.checked().length
    if (this.hasBarTarget) {
      this.barTarget.classList.toggle("hidden", n === 0)
      this.countTarget.textContent = n
    }
  }

  checked() {
    return this.boxTargets.filter(b => b.checked)
  }

  clear() {
    this.boxTargets.forEach(b => (b.checked = false))
    this.refresh()
  }

  opChanged() {
    const op = this.opTarget.value
    this.valueTargets.forEach(v => v.classList.toggle("hidden", v.dataset.op !== op))
  }

  async apply() {
    const ids = this.checked().map(b => b.value)
    if (!ids.length) return
    const op = this.opTarget.value
    if (op === "delete" && !confirm(`Excluir ${ids.length} tarefa(s) permanentemente?`)) return
    const valueSel = this.valueTargets.find(v => v.dataset.op === op)
    const body = new URLSearchParams()
    ids.forEach(i => body.append("task_ids[]", i))
    body.append("op", op)
    body.append("value", valueSel ? valueSel.value : "")
    await fetch(this.urlValue, {
      method: "POST",
      headers: { "X-CSRF-Token": this.csrfValue },
      body,
      credentials: "same-origin"
    })
    window.location.reload()
  }
}

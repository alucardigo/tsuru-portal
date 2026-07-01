import { Controller } from "@hotwired/stimulus"

// Cmd+K / Ctrl+K abre o command palette. Digita para buscar tasks/demands/users.
// Setas ↑ ↓ navegam, Enter abre, ESC fecha.
export default class extends Controller {
  static targets = ["overlay", "input", "results"]

  connect() {
    this._onKey = (e) => {
      if ((e.key === "k" || e.key === "K") && (e.metaKey || e.ctrlKey)) {
        e.preventDefault()
        this.open()
      } else if (e.key === "Escape" && this.isOpen()) {
        this.close()
      }
    }
    document.addEventListener("keydown", this._onKey)
    this._debounce = null
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKey)
  }

  isOpen() {
    return !this.overlayTarget.classList.contains("hidden")
  }

  open() {
    this.overlayTarget.classList.remove("hidden")
    setTimeout(() => this.inputTarget.focus(), 30)
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    this.inputTarget.value = ""
    this.resultsTarget.innerHTML = ""
  }

  backdrop(e) {
    if (e.target === this.overlayTarget) this.close()
  }

  search() {
    const q = this.inputTarget.value.trim()
    clearTimeout(this._debounce)
    if (q.length < 2) { this.resultsTarget.innerHTML = ""; return }
    this._debounce = setTimeout(async () => {
      const res = await fetch(`/search/quick?q=${encodeURIComponent(q)}`, { credentials: "same-origin" })
      const data = await res.json()
      this.render(data)
    }, 150)
  }

  render(data) {
    const section = (title, items, icon) => {
      if (!items.length) return ""
      const rows = items.map(i => `
        <a href="${i.path}" class="flex items-center gap-2 px-3 py-2 hover:bg-indigo-50 text-[12.5px] text-gray-900">
          <span class="text-gray-400">${icon}</span>
          <span class="flex-1 truncate">${(i.codigo ? `<span class='text-[10.5px] text-gray-500 font-mono mr-2'>${i.codigo}</span>` : "") + (i.demand ? `<span class='text-[10.5px] text-gray-500 mr-2'>${i.demand}</span>` : "") + (i.title || i.name)}</span>
          <span class="text-[10.5px] text-gray-400">${i.email || ""}</span>
        </a>`).join("")
      return `<div class="border-b border-gray-100 last:border-0"><div class="px-3 py-1 text-[10px] uppercase tracking-wider text-gray-400 font-semibold bg-gray-50">${title}</div>${rows}</div>`
    }
    this.resultsTarget.innerHTML =
      section("Projetos", data.demands || [], "📁") +
      section("Tarefas",  data.tasks   || [], "✓") +
      section("Pessoas",  data.users   || [], "👤")
  }
}

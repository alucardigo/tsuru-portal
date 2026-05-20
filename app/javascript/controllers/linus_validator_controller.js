import { Controller } from "@hotwired/stimulus"

// Valida texto contra Validators::LinusRedaction via POST /validators/linus.
// Faz debounce de 800ms enquanto o usuário digita e renderiza warnings.
//
// HTML esperado:
//   <textarea data-controller="linus-validator"
//             data-linus-validator-target="textarea"
//             data-linus-validator-warnings-outlet="#linus-warnings">
//   </textarea>
//   <div data-linus-validator-target="warnings"></div>
export default class extends Controller {
  static targets = ["textarea", "warnings"]
  static values = {
    url: { type: String, default: "/validators/linus" },
    debounce: { type: Number, default: 800 }
  }

  connect() {
    this.timer = null
    const ta = this.textareaTarget
    ta.addEventListener("input", () => this.scheduleValidate())
    ta.addEventListener("blur", () => this.validate())
  }

  scheduleValidate() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.validate(), this.debounceValue)
  }

  async validate() {
    const text = this.textareaTarget.value || ""
    if (text.length < 30) {
      this.renderWarnings(null)
      return
    }

    try {
      const csrfMeta = document.querySelector('meta[name="csrf-token"]')
      const headers = { "Content-Type": "application/json", "Accept": "application/json" }
      if (csrfMeta) headers["X-CSRF-Token"] = csrfMeta.content

      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: headers,
        body: JSON.stringify({ text: text, require_quantitative: true })
      })
      if (!response.ok) return
      const data = await response.json()
      this.renderWarnings(data.ok ? null : data.violations)
    } catch (e) {
      // Falha silenciosa — não atrapalha submit
    }
  }

  renderWarnings(violations) {
    if (!this.hasWarningsTarget) return
    if (!violations || violations.length === 0) {
      this.warningsTarget.innerHTML =
        `<div class="mt-2 flex items-start gap-2 px-2.5 py-1.5 rounded-md bg-emerald-50 ring-1 ring-emerald-200 text-emerald-800 text-[11.5px]">
          <span class="font-medium">Texto OK</span> — sem termos banidos e com quantitativos presentes.
        </div>`
      return
    }

    const items = violations.map(v => {
      if (v.type === "banned_phrase") {
        return `<li><strong>Termos banidos:</strong> ${(v.terms || []).join(", ")}</li>`
      }
      if (v.type === "pmo_disguised_as_technical") {
        return `<li><strong>Soa como gestão (PMO), não barreira técnica:</strong> ${(v.terms || []).join(", ")}</li>`
      }
      if (v.type === "missing_quantitative") {
        return `<li><strong>Sem quantitativos:</strong> ${v.message || "inclua métricas (ms, %, R$, MB…)"}</li>`
      }
      return `<li>${v.type}</li>`
    }).join("")

    this.warningsTarget.innerHTML =
      `<div class="mt-2 flex items-start gap-2 px-2.5 py-1.5 rounded-md bg-amber-50 ring-1 ring-amber-200 text-amber-900 text-[11.5px]">
        <div class="flex-1">
          <div class="font-medium mb-0.5">Linus diz: revise o texto</div>
          <ul class="list-disc pl-4 space-y-0.5">${items}</ul>
        </div>
      </div>`
  }
}

# AUDITORIA DE SPRINTS — Portal Tsuru PD&I

**Plano:** `X:\portal-inovacao-pdi\docs\sprints\2026-05-18-portal-pdi-plan.md`
**Repositório:** `X:\tsuru-portal`
**Data da auditoria:** 2026-05-19

---

## Mapeamento Commits x Tasks

| Sprint | Task ID | Título planejado | Commit(s) | Status | Observações |
|--------|---------|------------------|-----------|--------|-------------|
| 0 | 0.1 | Provisionar VM Oracle OCI | — | ❌ | Sem commit (task manual via console) |
| 0 | 0.2 | Bootstrap Rails 8 + RSpec + CI | f2089e4 | ✅ | "bootstrap Rails 8 + Hotwire + Tailwind + RSpec + CI" |
| 0 | 0.3 | Kamal 2 + Dockerfile | 7edfde8 | ⚠️ | Coberto parcial em "Kamal 2 OCI + Solid trio + Tailwind v4 + layout base Sprint 0" |
| 0 | 0.4 | PostgreSQL + Solid trio | 7edfde8 | ✅ | Mesmo commit acima |
| 0 | 0.5 | Tailwind base + layout | 7edfde8 | ✅ | Mesmo commit acima |
| 1 | 1.1 | Models User/Department/Role | 3e27040 | ✅ | "Sprint 1 — Devise+2FA+roles..." |
| 1 | 1.2 | Login UI + 2FA opcional | 3e27040 | ⚠️ | 2FA mencionado mas UI completa só veio em 84a30fc (Sprint 4) |
| 1 | 1.3 | Pundit + roles policy | 3e27040 | ✅ | Incluso no commit Sprint 1 |
| 1 | 1.4 | Demand + state machine | 3e27040 | ✅ | Incluso no commit Sprint 1 |
| 1 | 1.5 | Code generator demanda | 3e27040 | ⚠️ | Provável incluso, não explícito |
| 1 | 1.6 | Form submissão + controller | 3e27040 | ⚠️ | Provável incluso, não explícito |
| 1 | 1.7 | Anexos Active Storage | 6b134fc | ✅ | "Active Storage anexos com validacao tipo/tamanho" (Sprint 2.4 no commit) |
| 1 | 1.8 | Página "Minhas demandas" | 3e27040 | ⚠️ | Não explícito; assumido junto com Sprint 1 |
| 2 | 2.1 | Inbox avaliador técnico | dcccdb3 | ⚠️ | "triagem N1, dashboard por papel" — cobre parcial |
| 2 | 2.2 | Service Assign + RequestInfo | dcccdb3 | ⚠️ | Implícito |
| 2 | 2.3 | UI de devolução (modal) | — | ❌ | Sem evidência de commit |
| 2 | 2.4 | Comments threaded Turbo | dcccdb3 | ✅ | "comentarios append-only" |
| 2 | 2.5 | Notificações in-app ActionCable | 555666c | ⚠️ | Turbo broadcast só em sprint7.2, ActionCable não explícito |
| 2 | 2.6 | Notificações por e-mail | 4b81e19 | ✅ | "DemandMailer + Solid Queue async notifications" (tag sprint3.3) |
| 2 | 2.7 | Linha do tempo show demand | — | ❌ | Sem evidência |
| 3 | 3.1 | Model TechnicalRefinement | dcccdb3 | ⚠️ | "triagem N1" cobre conceito mas não modelo nomeado |
| 3 | 3.2 | UI refinamento multi-step | — | ❌ | Sem evidência |
| 3 | 3.3 | Service Refine/ClassifyPdi | dcccdb3 | ⚠️ | Possivelmente incluso |
| 3 | 3.4 | Admin CRUD users/depts | 4f8f941 | ✅ | "admin panel users/demands + CSV export" |
| 3 | 3.5 | Audit log PaperTrail | 7b4c84d | ⚠️ | "audit trail viewer com PaperTrail" — chegou na sprint 4 |
| 4 | 4.1 | LeiDoBemRecord + Membership + Expense | d0b6dec | ⚠️ | "avaliacao N2 FI Group + decisao de elegibilidade" (tag sprint3) |
| 4 | 4.2 | Validator Linus | — | ❌ | Sem evidência |
| 4 | 4.3 | UI bloco N2 validação ao vivo | d0b6dec | ⚠️ | Parcial em "avaliacao N2 FI Group" |
| 4 | 4.4 | Calculator LeiDoBemBenefit | — | ❌ | Sem evidência |
| 4 | 4.5 | UI calculadora painel | — | ❌ | Sem evidência |
| 4 | 4.6 | UI tabela dispêndios/equipe | — | ❌ | Sem evidência |
| 5 | 5.1 | SubmitToBoard | — | ❌ | Sem evidência |
| 5 | 5.2 | Painel "Para diretoria" | 00cc48b | ⚠️ | Commit usa tag sprint5.2 mas conteúdo é SankhyaService — DIVERGÊNCIA |
| 5 | 5.3 | Approve + BoardDecision | 82c07c3 | ⚠️ | Tag sprint-5.3 mas conteúdo é "exportação XLSX + DOCX" — DIVERGÊNCIA |
| 5 | 5.4 | ExecutiveDashboard service | 1343ac6 | ⚠️ | Tag sprint-5.4 mas conteúdo é "SimpleCov + CI" — DIVERGÊNCIA |
| 5 | 5.5 | UI dashboard executivo | b76afcd | ⚠️ | "dashboard metricas admin" (tag sprint6.1) — fora de ordem |
| 5 | 5.6 | Sankhya Client + Auth + SyncCC | ec8af1e | ✅ | "Sankhya OAuth client com circuit breaker" |
| 5 | 5.7 | FetchExpenses + Snapshot | 00cc48b | ⚠️ | "SankhyaService notas_fiscais" (não é expenses snapshot conforme planejado) |
| 6 | 6.1 | Sankhya CreateProject + Job | — | ❌ | Sem evidência (write Sankhya não implementado) |
| 6 | 6.2 | ComposeDocxDossier | 82c07c3, dab9a43 | ✅ | DOCX em 82c07c3, PDF N3 em dab9a43 (substitui em parte) |
| 6 | 6.3 | ComposeXlsxMapping 27 cols | 82c07c3 | ⚠️ | XLSX existe, mas 27 colunas exatas não verificadas |
| 6 | 6.4 | ExportFormpdJson + schema | ca91563 | ⚠️ | "exportação FORMP&D com TRL e ODS" (tag sprint-4.1) — fora de ordem; sem schema JSON validation |
| 6 | 6.5 | Pipeline PD&I (Kanban) | — | ❌ | Sem evidência |
| 6 | 6.6 | ComposeN3Defense Job | dab9a43 | ⚠️ | Dossiê N3 gerado, mas como PDF (Prawn) não como Job de composição automática |
| 7 | 7.1 | Performance pass / índices | 9dc9958 | ⚠️ | "paginacao Pagy v43" cobre parte |
| 7 | 7.2 | Security pass (Brakeman, CSP) | 43c9ac5 | ⚠️ | "Rack::Attack rate limiting" — não é Brakeman/CSP |
| 7 | 7.3 | Backups + DR | 9d7c30d | ❌ | Tag sprint7.3 mas conteúdo é "model specs Demand" — DIVERGÊNCIA total |
| 7 | 7.4 | Treinamento + docs | e53e44e | ❌ | Tag sprint7.4 mas conteúdo é "digest semanal" — DIVERGÊNCIA total |
| 7 | 7.5 | Soft-launch piloto | — | ❌ | Sem evidência |
| 7 | 7.6 | Deploy produção plena | fe61207 | ✅ | "deploy prod Kamal 2 + OCI Object Storage" (tag sprint-4.4) — fora de ordem |

---

## Análises

### 1. Tasks NO PLANO mas NÃO ENTREGUES (❌)
- **0.1** VM OCI (manual, esperado sem commit)
- **2.3** UI modal devolução
- **2.7** Linha do tempo show
- **3.2** UI refinamento multi-step
- **4.2** Validator Linus (CRÍTICO — peça-chave do plano Lei do Bem)
- **4.4, 4.5, 4.6** Calculadora + UI calculadora + tabela dispêndios
- **5.1** SubmitToBoard service
- **6.1** Sankhya write (CreateProject) — funcionalidade write não entregue
- **6.5** Pipeline Kanban
- **7.3** Backups/DR (commit com tag erra escopo)
- **7.4** Treinamento/PDFs (commit com tag erra escopo)
- **7.5** Soft-launch piloto

### 2. Commits SEM TASK correspondente (fora do plano)
- **a152e77** `fix(rack3): :unprocessable_entity → :unprocessable_content` — manutenção Rails
- **43c9ac5** `sprint6.4: Rack::Attack` — adicionado fora do plano original (poderia ser parte de 7.2)
- **555666c** `sprint7.2: Turbo broadcast live` — escopo Turbo broadcast não planejado dessa forma
- **9d7c30d** `sprint7.3: model specs Demand` — testes adicionais (substituiu DR)
- **e53e44e** `sprint7.4: digest semanal` — feature não planejada (substituiu treinamento)

### 3. Tasks parcialmente implementadas (⚠️) — 21 tasks
Várias tasks foram fundidas em commits únicos sem rastreabilidade fina. Destaque: Sprint 1 inteiro condensado em **3e27040**.

### 4. Ordem de execução vs ordem planejada
**A ORDEM NÃO FOI SEGUIDA.** Os tags dos commits (`sprint-4.1`, `sprint-5.3`, etc.) NÃO correspondem aos números reais do plano:
- Commits tagueados como sprint 4/5/6/7 entregam itens originalmente do sprint 3/4/5/6.
- A numeração `sprintN.M` foi usada como contador sequencial de entregas, não como referência ao plano.
- Exemplos:
  - `sprint-4.1` (ca91563) entrega export FORMP&D = Task **6.4** no plano
  - `sprint-4.4` (fe61207) entrega deploy Kamal = Task **7.6** no plano
  - `sprint5.2` (00cc48b/ec8af1e) entrega Sankhya = Task **5.6/5.7**
  - `sprint6.1` (b76afcd) entrega dashboard = Task **5.5**
  - `sprint7.3/7.4` entregam digest e specs — fora do escopo de hardening planejado

---

## Veredito Final

**Sprints planejados:** 8 (Sprints 0 a 7)
**Sprints executados (com commits):** 8 (todos têm pelo menos um commit, mas conteúdo divergente)

**Tasks planejadas:** 46
- Plenamente entregues (✅): **11** (24%)
- Parcialmente entregues (⚠️): **21** (46%)
- Não entregues (❌): **14** (30%)

**Cobertura do plano original (full + parcial): ~70%**
**Cobertura estrita (somente ✅): ~24%**

**Tasks "fora do plano original" (escopo extra/substituições):**
- Rack::Attack rate limiting (43c9ac5)
- Turbo broadcast live state (555666c)
- Digest semanal PD&I (e53e44e)
- Model specs adicionais (9d7c30d)
- Fix Rails 7.1→7.2 migration (a152e77)
- Relatório PDF Prawn (dab9a43) — substitui DOCX dossiê parcialmente
- Filtro avançado admin (3fbb9c5) — não está no plano

**Lacunas críticas (alto impacto regulatório/funcional):**
1. **Validator Linus Redação (4.2)** — peça central do compliance Lei do Bem, NÃO implementada
2. **Calculadora benefício Lei do Bem (4.4/4.5)** — base do ROI fiscal, NÃO implementada
3. **Sankhya write/CreateProject (6.1)** — integração write com ERP NÃO implementada
4. **JSON Schema FORMP&D (6.4)** — validação contra schema MCTI ausente
5. **DR/Backups (7.3)** — runbook ausente
6. **Soft-launch piloto (7.5)** — etapa de validação real pulada

**Recomendação:** Renumerar commits futuros com tag correta do plano (ex.: `task-4.2`) e priorizar fechar lacunas críticas (4.2, 4.4, 6.1) antes do soft-launch.

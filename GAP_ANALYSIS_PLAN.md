# Gap Analysis vs plano oficial portal-inovacao-pdi

> Auditoria executada em 2026-05-20 comparando PRD/Sprint Plan/Design System (X:\portal-inovacao-pdi\docs) vs implementação atual (X:\tsuru-portal).
> Base: 350 specs verdes, 75.87% coverage, sprints 1–10.6 declarados completos.

---

## Veredito em 3 frases

A esteira N1 → N2 → decisão de elegibilidade está sólida e visualmente coerente (Notion-style refinado em Sprint 10), com calculator/validator Linus/FORMP&D schema já em service objects, mas três pilares do PRD V1 estão **AUSENTES da UI ou subimplementados**: (1) **Dispêndios + Equipe + Parcerias + Calculadora de benefício fiscal** — modelos `Expense/TeamMember/Partnership` existem mas **não há CRUD, view, nem rota** para o focal técnico preencher; (2) **Painel Board/Diretoria** — sidebar tem item `decisoes` apontando para `demands_path` placeholder, sem fluxo de Aprovar/Rejeitar/Adiar com justificativa estruturada (transição `enviar_para_board` existe no state machine mas não tem UI); (3) **Notificações in-app + Sankhya jobs agendados + Pipeline Kanban PD&I** — só existe e-mail (DemandMailer), zero ActionCable channel para sininho, zero job recurring para `SyncSankhyaCostCentersJob/FetchSankhyaExpensesJob/CreateSankhyaProjectJob`. Há também placeholders evidentes: sidebar com `path: "#"` em "Biblioteca PD&I", "Composição defesa", "Evidências", "Exportar" do board, SSO "em breve" no login, e campos UI-only no form de submissão (`area_impactada_ui`, `urgencia_ui`, `solucao_ui`) que **não persistem** em coluna nenhuma.

---

## Tabela de gaps por prioridade

| Prio | Categoria | Gap específico | Arquivo / fluxo | Esforço |
|------|-----------|----------------|-----------------|---------|
| P0 | Tela faltando | Dispêndios PD&I CRUD (RH/ST/MC) — sem view nem controller | Falta `app/views/lei_do_bem/expenses/*`, `expenses_controller.rb` | M (8h) |
| P0 | Tela faltando | Equipe PD&I CRUD (CPF, titulação, dedicação) | Falta `app/views/lei_do_bem/team_members/*` | M (8h) |
| P0 | Tela faltando | Parcerias ICT/Universidade CRUD | Falta `app/views/lei_do_bem/partnerships/*` | S (4h) |
| P0 | Tela faltando | **Calculadora benefício fiscal embutida** — service existe, sem UI | `Calculators::LeiDoBemBenefit` está pronto; falta partial `_benefit_calculator.html.erb` + Turbo Frame auto-refresh | M (6h) |
| P0 | Funcionalidade parcial | **Diretoria/Board** — role existe, nav aponta para `dashboard_path` e `#`, sem fluxo Aprovar/Rejeitar/Adiar | `board_review` é estado válido + evento `enviar_para_board` existe, mas sem `board/demands_controller`, sem `board/demands/index.html.erb`, sem `BoardDecision` model | L (12h) |
| P0 | Funcionalidade parcial | **Form de submissão com 3 campos UI-only que não persistem** (`area_impactada_ui`, `urgencia_ui`, `solucao_ui`) — usuário preenche e perde | `app/views/demands/_form.html.erb` linhas 54–89 + `demand_params` linha 148 só permite `:title, :description, attachments` | S (3h) |
| P0 | Gap UX | Sidebar com 5 links apontando para `path: "#"` — "Biblioteca PD&I" (3x: colaborador/gestor/analista), "Composição defesa" (analista), "Evidências" (analista), "Exportar" (board) | `app/helpers/ui_helper.rb` linhas 96, 103, 110–112, 127 | S (2h cada se virar empty-state) |
| P1 | Funcionalidade parcial | **Notificações in-app via ActionCable (sininho)** — só existe e-mail (`DemandMailer`), nenhum `NotificationsChannel`, nenhum modelo `Notification` | Sininho no topbar é um botão visual sem badge dinâmico nem subscription | M (8h) |
| P1 | Funcionalidade parcial | **Sankhya jobs agendados** — `Sankhya::Client` existe (auth OAuth + circuit breaker), mas só `SankhyaService.notas_fiscais` está em uso. Faltam: `SyncSankhyaCostCentersJob`, `CreateSankhyaProjectJob` (ao aprovar), `FetchSankhyaExpensesJob` semanal, modelo `ExpenseSnapshot`, `Department` model | M (10h) |
| P1 | Tela faltando | **Pipeline Kanban PD&I** (US-017) — colunas Triagem N1 / Avaliação N2 / Em execução / Defesa N3 / Submetido MCTI / Concluído | Nenhuma rota, nenhuma view, nenhum controller `pdi/pipeline` | M (6h) |
| P1 | Gap UX | Linha do tempo da demanda (US-019) mostra só "criou" + "último comentário" — não consolida `demand_transitions` ordenado | `demands/show.html.erb` linhas 387–462 está hardcoded em 5 steps fixos, não lê `DemandTransition` real | S (4h) |
| P1 | Funcionalidade parcial | `DemandTransition` model existe, append-only trigger declarado (sprint 8.1), mas nenhuma transição AASM grava registro — `after_transition` callback não é wired | `app/models/demand.rb` state_machine não tem `after_transition do ... DemandTransition.create! ... end` | S (3h) |
| P1 | Gap UX | **Empty states fracos**: dashboard sem demandas mostra ícone+texto mas não orienta gestor/analista/board (só colaborador tem CTA); admin/users sem filtros (só lista todos) | `dashboard/show.html.erb` linhas 67–78; `admin/users/index.html.erb` | S (3h) |
| P1 | Tela faltando | View **detalhe da decisão Board com Executive Summary + ROI + impacto fiscal** (US-009 acceptance criteria) | Nenhum lugar exibe o cálculo `Calculators::LeiDoBemBenefit` mesmo para demandas elegíveis | M (5h) |
| P2 | Funcionalidade parcial | Edit de demanda redireciona para `_form.html.erb` que tem header "Registrar nova ideia" mesmo quando `demand.persisted?` em alguns caminhos; texto está parcialmente OK mas footer ainda mostra "Salvar como rascunho" sempre | `_form.html.erb` linha 138 | XS (1h) |
| P2 | Gap UX | **Validador Linus** existe (`Validators::LinusRedaction`) mas não é exibido em tempo real no N2 form — só pode ser via `demand.linus_violations` chamado em algum lugar (não vi) | `app/views/demands/n2.html.erb` não chama `linus_violations` nem renderiza warnings amarelos | S (3h) |
| P2 | Funcionalidade parcial | TRL e ODS aparecem em `show`/`n2` mas não há **formulário para colaborador/analista editar** TRL e ODS — só ficam visíveis se já foram salvos por algum caminho (qual?) | Não encontrei view para editar TRL/ODS | S (3h) |
| P2 | Funcionalidade parcial | **Workflow `awaiting_requester` / `solicitar_revisao` / `retomar`**: eventos existem na state machine, mas nenhuma UI tem botão "Devolver com pergunta" ou "Reenviar" — fluxo de devolução do PRD (US-005) não está acessível | Falta modal em `demands/show.html.erb` | M (5h) |
| P2 | Funcionalidade parcial | Anexos com dropzone visual presente, mas **upload é multipart síncrono** — sem `direct_upload`, sem Stimulus controller para progress, sem validação client-side de 10MB | `_form.html.erb` linha 108 | S (3h) |
| P2 | Gap UX | Loading states ausentes em formulários submitam (Turbo cuida do redirect, mas sem `aria-busy` ou skeleton em listagens) | Toda view | S (2h) |
| P2 | Funcionalidade parcial | Export XLSX/DOCX/CSV admin é **lista achatada de 8 colunas** — PRD pede `Modelo Mapeamento FI Group 2026 com 27 colunas A-AC` | `admin/demands_controller.rb` linhas 60–104 | M (5h) |
| P2 | Funcionalidade parcial | Exportação JSON FORMP&D existe (`demand.to_formpd`) mas é mínima (8 campos, sem `team`/`expenses`/`partnerships`/`technical_barriers`/`ods_codes`/`trl_target` etc.) e não roda pelo `Validators::FormpdSchema` antes de servir | `app/models/demand.rb` linha 137 | S (3h) |
| P3 | Compliance | DIRBI CSV exportável (mapping §7) — não implementado | Não existe | S (4h) |
| P3 | Compliance | Composição automática N3 via job (`ComposeN3DefenseJob`) — mapping §2.3 fala em pré-popular `barriers_consolidated` etc. | `N3PdfService` existe mas só renderiza PDF do que já está no `Demand`, sem agregar `demand_transitions` | M (6h) |
| P3 | Auth | SSO Azure/Okta marcado "em breve" no login — fora do MVP segundo Q-01, OK adiar | `users/sessions/new.html.erb` linha 64 | — |

---

## Telas que faltam (do PRD/design-system) que não foram implementadas

- **Painel Diretoria/Board** — `board/demands#index` e `board/demands#show` com Executive Summary, ROI estimado, impacto fiscal e botões Aprovar/Rejeitar/Adiar com justificativa min 100 chars (US-009, design §5.3). Sidebar do board já está pronto mas links são placeholders.
- **CRUD Dispêndios PD&I** — tabela de despesas RH/ST/MC com vínculo a centro de custo Sankhya (US-008).
- **CRUD Equipe PD&I** — colaboradores envolvidos com CPF, titulação, dedicação % (US-008).
- **CRUD Parcerias ICT/Universidade** — model `Partnership` existe mas zero UI (mapping §3 col P; US-008).
- **Calculadora de benefício fiscal embutida no N2** — painel lateral Turbo Frame que se auto-atualiza ao mudar dispêndios + toggle "patente concedida" / "incremento >5% pesquisadores" (US-018). Service `Calculators::LeiDoBemBenefit` pronto, sem UI.
- **Pipeline PD&I Kanban** — 6 colunas (Triagem N1 / Avaliação N2 / Em execução / Defesa N3 / Submetido / Concluído) com cards de % preenchimento (US-017, design §4.4).
- **Sininho de notificações in-app** — topbar tem ícone mas sem contador real, sem `NotificationsChannel`, sem modelo `Notification`.
- **Inbox dedicada do avaliador técnico** — hoje vai pelo dashboard genérico, não há `inbox/demands_controller` com filtros de idade+urgência+ações rápidas (US-004).
- **Tela de devolução com modal Turbo** — botão "Devolver pedindo info" disparando `solicitar_revisao` (US-005).
- **Biblioteca PD&I** — link em 3 papéis aponta para `#`. Não foi escopado no PRD MVP, mas está visível no menu prometendo navegação.
- **Editor de TRL e ODS** — campos existem em colunas, mas não há formulário para preencher fora de migration manual.

---

## Telas implementadas mas com falhas funcionais

- **`demands/_form.html.erb`** — 3 campos UI-only (`area_impactada_ui`, `urgencia_ui`, `solucao_ui`) coletam dados do colaborador que são **descartados no submit** porque `demand_params` só permite `title/description/attachments`. Quebra confiança do usuário e é regressão clara.
- **`demands/show.html.erb` linha 76/94** — propriedades "Área" e "Responsável T&I" mostram literal "—" / "a designar" em itálico cinza (campos não existem no model `Demand`).
- **`demands/show.html.erb` linhas 387–462 (Linha do tempo)** — hardcoded em 5 steps fixos baseados em `flow_step_for(state)`; ignora `DemandTransition` real (que aliás não é gravado por nenhum callback AASM atual).
- **`dashboard/show.html.erb` linha 4–28** — saudação por role OK, mas para `board` e `admin` o "Olá" não mostra dados executivos (KPIs ainda são `submetidas + em_triagem` etc., não ROI/benefício fiscal).
- **`demands/n2.html.erb`** — formulário robusto e bonito, mas não chama `Validators::LinusRedaction` ao vivo, não exibe warnings amarelos para "otimização sem nº", não bloqueia salvar quando barreira técnica não tem quantitativo (PRD §7 / US-007 / mapping §2.2 exigem).
- **`admin/demands#index` exports** — XLSX/DOCX/CSV têm 8 colunas; PRD §11 exige Modelo Mapeamento FI Group 2026 com 27 colunas A-AC.
- **`admin/demands#formpd`** — `render json: demand.to_formpd` retorna 8 campos sem `team/expenses/partnerships/technical_barriers/ods_codes/trl_target/experimental_approaches/sector_typology/innovation_scope` — não validado contra `lib/schemas/formpd_v2026.json` apesar do schema e validator existirem.
- **`admin/demands#sankhya`** — só consulta `notas_fiscais` por CODPARC; não sincroniza centros de custo periodicamente, não cria projeto Sankhya ao aprovar, não rebate dispêndios em `ExpenseSnapshot` (tabela que nem existe).
- **`comments` Turbo Streams** — `create.turbo_stream.erb` existe, mas a partial `comments/_comment` não tem indicador "novo" nem broadcast multi-user (só refresca para o autor da ação).
- **`users/sessions/new.html.erb` linha 64** — "Entrar com SSO corporativo (em breve)" — botão `disabled`. OK adiar (Q-01) mas é placeholder visível em produção.

---

## Plano de ataque ordenado (Sprint 11.3+)

1. **Task 11.3.A — Wire dos 3 campos UI-only no form de submissão (3h, P0)** — decidir entre (a) adicionar colunas `area_impactada`, `urgencia`, `solucao_proposta` em `demands` + permitir nos params, ou (b) remover campos do form. Sem isso o usuário perde dados visivelmente.
2. **Task 11.3.B — CRUD Dispêndios + Equipe + Parcerias + Calculadora embutida (24h, P0)** — criar `lei_do_bem/expenses_controller`, `team_members_controller`, `partnerships_controller` aninhados em `demands/:id/lei_do_bem`; partial `_benefit_calculator.html.erb` consumindo `Calculators::LeiDoBemBenefit` com Turbo Frame auto-refresh + toggles "patente" e "incremento >5%". Inclui migration `lei_do_bem_records.id` 1:1 com `demand` quando elegível.
3. **Task 11.3.C — Painel Diretoria/Board com fluxo Aprovar/Rejeitar/Adiar (12h, P0)** — `board/demands_controller`, modelo `BoardDecision` (justificativa min 100 chars), views index/show com Executive Summary + ROI + benefício fiscal, sidebar do board apontando para rotas reais. Wire-up do evento AASM `enviar_para_board` no `show.html.erb` quando estado for `n2_completa` e analista_pdi marcou elegível.
4. **Task 11.3.D — Notificações in-app (sininho funcional) via ActionCable (8h, P1)** — modelo `Notification(recipient, kind, demand, read_at, payload jsonb)`, `NotificationsChannel`, `Notifications::Dispatcher` chamado pelos callbacks AASM, partial `_notification_bell.html.erb` no topbar com badge contador + dropdown últimos 10.
5. **Task 11.3.E — Wire-up `DemandTransition` + Linha do tempo real (4h, P1)** — adicionar `after_transition` no state machine de `Demand` gravando `DemandTransition.create!(user, from, to, justification)`. Substituir os 5 steps hardcoded em `demands/show.html.erb` por loop sobre `demand.transitions.includes(:user).order(:created_at)`.

> Cada task é autocontida e delegável a um agente Codex/Qwen com `cd X:\tsuru-portal && bundle exec rspec` como verificação. Total estimado: 51h (~6,5 dias-pessoa). Sprint 11.3 enxuto = Tasks A + B + C (39h). Sprint 11.4 = D + E + começo do Pipeline Kanban.

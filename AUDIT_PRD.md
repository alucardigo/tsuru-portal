# Auditoria PRD vs. Implementação — Portal Tsuru PD&I

**Auditor:** modo Linus + DHH (brutalmente honesto)
**Data:** 2026-05-19
**Escopo:** PRD v1.0 + mapeamento Lei do Bem vs. `X:\tsuru-portal\` (Rails 8, 231 specs)

---

## 1. Papéis (Personas / Roles)

| Item | Status | Observação |
|---|---|---|
| Roles: colaborador, gestor, analista_pdi, admin, board | ⚠️ | Enum existe em `User`, mas PRD pede `requester, area_manager, tech_evaluator, innovation_lead, director, admin` (6 roles). Mapeamento é ad-hoc; faltam multi-roles por usuário (PRD §F-MVP-02 / US-020). |
| Role `board` | ⚠️ | Existe enum, mas **nenhuma policy diferencia board de gestor**. Diretor não tem painel dedicado nem fluxo de aprovação (US-009). |

## 2. Fluxos / Máquina de estados

| Requisito PRD | Status | Gap |
|---|---|---|
| 13 estados, 18 transições (§6) | ❌ | Implementados 10 estados, 9 transições. **Faltam:** `awaiting_requester`, `technical_refinement`, `pdi_classification`, `improvement_pipeline`, `board_review`, `approved`, `in_execution`, `completed`, `abandoned`, `archived_in_year_base`. Modelo atual usa `rascunho/submetida/em_triagem/n1_*/n2_*/elegivel/nao_elegivel/cancelada`. |
| Devolução `request_info` → `awaiting_requester` (US-005, FR-10) | ❌ | Não existe. Sem loop solicitante↔avaliador. |
| Refinamento técnico com pré-classificação PD&I (US-006) | ❌ | Não existe estado dedicado nem campos de diagnóstico/esforço/tecnologias previstas. |
| Aprovação pela diretoria (US-009, board_review→approved) | ❌ | Não há fluxo de diretoria. Não há `submit_to_board`, `approve`, `defer`, `reject`. |
| Execução + conclusão + arquivamento ano-base | ❌ | Estados ausentes. Não há ciclo de vida pós-elegibilidade. |
| Tabela `demand_transitions` append-only com trigger PG (FR-07, FR-08, US-019) | ❌ | Não existe. Auditoria depende exclusivamente do PaperTrail (`versions`). Sem trigger PG bloqueando UPDATE/DELETE. |

## 3. Submissão / Anexos

| Requisito | Status | Gap |
|---|---|---|
| Formulário com problema, solução, ganho esperado, setor, urgência (US-002) | ❌ | `Demand` só tem `title` + `description`. Campos `solucao_proposta`, `ganho_esperado`, `setor`, `urgencia` **inexistem**. |
| Anexos PDF/PNG/JPG/XLSX/DOCX/MP4/MOV (FR-03) | ⚠️ | MP4/MOV ausentes. Limite individual é **10MB** (PRD pede 500MB; FR-04 cita 5GB agregado). Sem `link externo`. |
| Salvar como rascunho (FR-10) | ✅ | Estado `rascunho` é o default. |
| Confirmação visual + SLA "5 dias úteis" | ❌ | Mensagem flash genérica, sem SLA. |

## 4. Lei do Bem — N1 / N2 / N3

| Requisito | Status | Gap |
|---|---|---|
| N1: 5 quesitos exatos do FI Group (mapping §2.1) | ⚠️ | 5 flags existem (`rotina_operacional`, `adequacao_normativa`, `solucao_prateleira`, `trl_fora_janela`, `escopo_nao_tecnologico`). **`trl_fora_janela` é inventado**; PRD pede `ideation_only` + `stabilization_only` (4.1 e 4.2 separados). |
| N2: 6 grupos, validações min 150/200 chars (mapping §2.2) | ❌ | Campos N2 são `motivacao/benchmark_anterior/barreira_tecnica/metodologia/stack_tecnologico/resultado_obtido` — **não casa** com mapping (escopo, baseline_state, target_state, technical_barriers, experimental_approaches, methodology_phases). Sem `min: 150/200` chars, sem `trl_initial/trl_target`, sem `project_nature`, sem `sector_typology`, sem `innovation_scope`. |
| Validador Linus-taste (US-007, FR-13) | ❌ | **Não implementado.** Nenhuma classe `Validators::LinusRedaction`. Não há regex de termos banidos nem exigência quantitativa. |
| Cálculo de benefício fiscal (US-018, FR-14, mapping §5) | ❌ | **Não existe** `Calculators::LeiDoBemBenefit`. Nenhum cálculo IRPJ/CSLL. |
| Tabelas de dispêndios + equipe PD&I (US-008) | ❌ | **Modelos inexistentes:** sem `expenses`, sem `team_members`, sem `partnerships`. |
| Sincronização N1 com FI Group framework (mapping §2.1) | ⚠️ | Lógica "qualquer SIM = reprovado" existe (`reprovado_n1?`), mas nomenclatura divergente. |
| N3 dossiê com `LeiDoBemDefense` (mapping §2.3) | ❌ | Modelo `LeiDoBemDefense` não existe. PDF N3 só consolida N2 + parecer; **faltam** 11 campos do mapping (success_criteria, technological_gains, barriers_consolidated, etc.). |

## 5. Integrações Sankhya

| Requisito | Status | Gap |
|---|---|---|
| Sync diário CentroResultado (US-013) | ❌ | `SyncSankhyaCostCentersJob` não existe. Sem modelo `Department` ou `CostCenter`. |
| Criação de projeto em aprovação (US-014) | ❌ | `CreateSankhyaProjectJob` não existe. `SankhyaService#registrar_adiantamento` é para outro fim. |
| Leitura semanal de dispêndios (US-015, FR-16) | ❌ | `FetchSankhyaExpensesJob` + `expense_snapshots` ausentes. |
| OAuth 2.0 Client Credentials | 🤷 | `SankhyaClient` mencionado mas não inspecionado; PRD exige Circuit Breaker (stoplight) — gem está no Gemfile, uso é desconhecido. |

## 6. Exportações

| Requisito | Status | Gap |
|---|---|---|
| CSV listagem básica | ✅ | `admin/demands#index.csv`. |
| XLSX 27 colunas A-AC FI Group 2026 (FR-18, US-011) | ❌ | XLSX atual exporta **8 colunas** genéricas. **Sem** as 27 colunas do mapping §3. |
| DOCX padrão N1/N2/N3 FI Group (FR-17) | ⚠️ | Existe DOCX rudimentar, mas é listagem de demandas — **não** segue estrutura N1/N2/N3 prescrita. |
| PDF N3 | ⚠️ | `N3PdfService` existe mas é incompleto (4 seções vs. 11 campos N3 do mapping). |
| JSON FORMP&D Portaria 9.563/2025 (FR-19, US-012) | ❌ | `Demand#to_formpd` retorna 8 campos com `schema_versao: "FORMPD-2025"`. **Sem** team, expenses, partnerships, ods_codes formatados, project_nature, nature enum, validação JSON Schema. Não bate com schema do mapping §4. |
| Exportação CSV DIRBI (mapping §7) | ❌ | Não existe. |
| Geração assíncrona via Solid Queue | ❌ | Exportações são síncronas no controller. |

## 7. Dashboard / Painéis

| Requisito | Status | Gap |
|---|---|---|
| Dashboard executivo 6 KPIs (US-010, FR-20) | ⚠️ | `dashboard#show` mostra contadores básicos. **Faltam:** taxa aprovação, ROI acumulado, benefício fiscal estimado, top 5 setores, distribuição TRL. `admin/metrics#show` tem TRL/ODS mas não ROI/fiscal. |
| Gráficos (linha temporal, barras, pizza) | ❌ | Apenas tabelas HTML. |
| Pipeline PD&I Kanban (US-017) | ❌ | Não existe Kanban nem visualização por TRL/% preenchimento. |
| Filtros ano-base, setor, status | ⚠️ | Filtros admin existem para status/TRL/data, **sem** ano-base ou setor. |
| Exportação dashboard PNG/CSV | ❌ | Não implementado. |

## 8. Segurança / Auditoria

| Requisito | Status | Gap |
|---|---|---|
| Devise + 2FA TOTP (FR-22, FR-23, US-001) | ✅ | `devise-two-factor` + `rqrcode` instalados; controllers de setup existem. |
| Bloqueio após 5 falhas em 10min | ⚠️ | Rack::Attack limita 5 logins/20s por IP (PRD pede 10min). Faltam `Devise::Lockable`. |
| Senha min 12 chars com composição | 🤷 | Não confirmado no `User`/`devise.rb`. |
| Pundit policies | ⚠️ | Existe `DemandPolicy`, mas distinções de role são frouxas e role `board` é tratada como `gestor`. |
| PaperTrail | ✅ | Ativo em `User`, `Demand`, `Comment`. |
| Rack::Attack | ✅ | Login + TOTP + Sankhya throttled. |
| Trigger PG append-only (FR-08) | ❌ | Não existe. |
| LGPD (anonimização, log de acessos) | ❌ | Sem direito ao esquecimento. |
| Backup automático PG diário (FR-25) | 🤷 | Sem evidência de Kamal/cron de backup. |

## 9. NFRs / Outros

| Requisito | Status | Gap |
|---|---|---|
| Notificações in-app via ActionCable (US-016, FR-09) | ⚠️ | Apenas 1 broadcast turbo no `iniciar_triagem`. Sem sininho, sem contador, sem inbox. E-mail funciona via `DemandMailer`. |
| Cobertura testes ≥85% models | ⚠️ | 88.63% global (PRD distingue por camada; ok como aproximação). |
| i18n PT-BR | ⚠️ | Locales presentes (uso de `t(...)`), mas sem confirmação de cobertura total. |
| Performance P95 ≤300ms | 🤷 | Sem benchmark anexado. |
| WCAG AA | 🤷 | Não auditado. |
| Comentários encadeados (US-019, F-MVP-09) | ⚠️ | Modelo `Comment` existe; thread polimórfica em campo/anexo não. |
| Kamal deploy | 🤷 | Gem instalada, configuração não verificada. |

---

## Veredito

**Pronto (≈20%):** infraestrutura Rails 8 está sólida — Devise+2FA, Pundit, PaperTrail, Rack::Attack, exportações básicas CSV/XLSX/DOCX, máquina de estados de triagem N1/N2 simplificada, PDF N3 minimalista, integração Sankhya pontual para 2 endpoints, 88% de cobertura.

**Falta urgente (bloqueia uso real para Lei do Bem):** modelos `LeiDoBemRecord`, `LeiDoBemDefense`, `Expense`, `TeamMember`, `Partnership`; calculadora de benefício fiscal; validador Linus-taste; fluxo board_review + aprovação diretoria; loop devolução `awaiting_requester`; XLSX 27 colunas A-AC; JSON FORMP&D conforme schema MCTI; jobs Sankhya (sync CentroResultado, criação projeto, fetch dispêndios); trigger PG append-only; campos extras na demanda (setor, urgência, solução proposta, ganho esperado).

**Pode ficar para depois:** Kanban Pipeline PD&I, dashboard com gráficos visuais, exportação DIRBI CSV, anonimização LGPD, suporte a anexos MP4/MOV de 500MB, link externo validado, notificações in-app com sininho, dashboard PNG, alertas de prazo DIRBI. O codinome "Tsuru" cobre apenas a metade superficial do funil — toda a esteira fiscal-tecnológica (N2 sério, N3, FORMP&D real, dispêndios) precisa ser reconstruída antes do primeiro ano-base de produção.

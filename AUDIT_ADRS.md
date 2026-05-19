# Auditoria de ADRs — Portal Tsuru PD&I

**Data:** 2026-05-19 | **Auditor:** Claude Code (modo arquitetural)
**Escopo:** `X:\tsuru-portal\` vs. `X:\portal-inovacao-pdi\docs\architecture\`

## Tabela de Conformidade

| ADR | Decisão | Status | Evidência | Violações |
|---|---|---|---|---|
| **ADR-001** | Rails 8 + Hotwire + Tailwind + Importmap (sem React/Vue/Webpacker) | OK | `Gemfile:3,7,8,9,10` (rails 8.1.3, importmap-rails, turbo-rails, stimulus-rails, tailwindcss-rails); sem `package.json`; `config/importmap.rb` presente | Rails 8.1.3 difere da especificação 8.0.x do overview (minor) |
| **ADR-003** | Solid Queue/Cache/Cable (sem Redis) | OK | `Gemfile:58-60` (solid_cache, solid_queue, solid_cable) | Nenhuma |
| **ADR-004** | Monólito majestoso (sem engines, sem microservices) | OK | Sem pastas `lib/engines` ou `engines/`; tudo em `app/` único | Nenhuma |
| **ADR-007** | gem `state_machines` (não AASM) | OK | `Gemfile:20` (state_machines-activerecord); `app/models/demand.rb:30` (`state_machine :aasm_state, initial: :rascunho do`) | Nome de coluna `aasm_state` é confuso (legado AASM); nenhum `update_column` no codebase |
| **ADR-009** | Sankhya Service Objects com namespace `Sankhya::` + Result struct + idempotência + retry | PARCIAL | `app/services/sankhya_client.rb`, `sankhya_service.rb` (Faraday + retry + Stoplight presentes) | (1) Classes fora de módulo `Sankhya::` (deveria ser `Sankhya::Client`, `Sankhya::CreateProject` etc); (2) **NENHUM Result struct** (`Result.new` retorna 0 matches em todos os services); (3) Sem mappers explícitos; (4) Sem idempotency_key; (5) Sem AuditLog.record!; (6) Sem `correlation_id` no log; (7) Não segue estrutura prescrita `app/services/sankhya/{client,auth,mappers,...}` |
| **ADR-011** | Append-only via PG triggers em `demand_transitions` e `demand_comments` | VIOLADO | `db/migrate/20260519135350_create_comments.rb` (sem trigger); tabela `demand_transitions` **não existe** | (1) Migration `comments` SEM `prevent_update_delete` trigger; (2) Tabela `demand_transitions` não foi criada — transições da state machine NÃO são persistidas em histórico; PaperTrail (`versions`) está OK em User e Demand mas não substitui o histórico explícito de transições |

## Violações Adicionais (CLAUDE.md §3)

| Regra | Status | Evidência |
|---|---|---|
| §3.3 Controllers thin (sem lógica) | VIOLADO | `demands_controller.rb:71-86` (update_triagem com `if reprovado_n1? / elsif aprovar_n1` — lógica de decisão de transição), `:113-130` (decidir_elegibilidade com `case decisao`) — deveriam virar `Demands::AvaliarTriagem` e `Demands::DecidirElegibilidade` |
| §3.4 Service Objects com `Result` struct | VIOLADO | `app/services/` tem 3 arquivos; nenhum usa `Result = Struct.new(:success?, :payload, :reason, :errors, ...)`; `SankhyaService#notas_fiscais` retorna array cru; `N3PdfService#render` retorna bytes |
| §3.8 JS total ≤ 500 linhas; Stimulus ≤ 50 linhas | OK | Total: 34 linhas JS (3+9+11+7+4); maior controller (dismissable) tem 11 linhas |
| §7 Anti-padrão: `update_column(:state, ...)` | OK | 0 ocorrências |
| §3.7 PaperTrail em modelos críticos | PARCIAL | `User` e `Demand` têm `has_paper_trail`; `Comment` NÃO tem; `LeiDoBemRecord` e `BoardDecision` não existem ainda |
| Estrutura de pastas por bounded context (`app/services/demands/`, `app/services/sankhya/`, `app/services/innovation/`) | VIOLADO | `app/services/` é plano: `n3_pdf_service.rb`, `sankhya_client.rb`, `sankhya_service.rb` — sem namespacing |

## Achados Críticos

1. **ADR-011 quebrado:** ausência de tabela `demand_transitions` significa que o histórico de máquina de estados (essencial para defesa CAT-MCTI/RFB) **não está sendo gravado**. PaperTrail cobre changes genéricos mas não o histórico semântico de eventos.
2. **ADR-009 superficial:** `SankhyaService` é um wrapper HTTP minimalista; falta encapsulamento prescrito (idempotência, mappers, Result, AuditLog, correlation_id).
3. **CLAUDE.md §3.4 sistematicamente ignorado:** zero `Result` structs no codebase. Controllers recebem booleans crus e fazem ramificação manual.
4. **Lógica de negócio em controllers:** `update_triagem` (16 linhas de decisão), `decidir_elegibilidade` (18 linhas com `case`) violam §3.3 e §4.1 do overview.

## Veredito Final

**ADRs respeitados: 3/6** (ADR-001, ADR-003 implícito no Gemfile, ADR-004, ADR-007).
**ADRs parciais: 1/6** (ADR-009).
**ADRs violados: 1/6** (ADR-011).

**Violações críticas:**
- (CRÍTICA) Tabela `demand_transitions` ausente + triggers PG append-only inexistentes → invalida defesa fiscal CAT-MCTI.
- (CRÍTICA) Service Objects sem `Result` struct (CLAUDE.md §3.4) — quebra contrato arquitetural.
- (ALTA) Lógica de transição/decisão dentro de `DemandsController#update_triagem` e `#decidir_elegibilidade`.
- (ALTA) Namespace `Sankhya::` ausente; estrutura de pastas plana em `app/services/`.

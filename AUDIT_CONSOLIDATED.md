# Auditoria Consolidada — Portal Tsuru PD&I

> Revisor sênior em modo Linus + DHH. Brutalmente honesto. Sem complacência.
> Data: 2026-05-19 · 26 commits · 231 specs · 88.63% coverage

## Veredito final em 3 frases

1. **A casca funciona, o núcleo está vazio.** O app sobe, autentica, roda triagem N1, exporta CSV/XLSX/DOCX/PDF e tem suite verde — mas o motor fiscal da Lei do Bem (calculadora IRPJ/CSLL, validador Linus, modelos `LeiDoBemRecord`/`Expense`/`TeamMember`/`Partnership`, FORMP&D validado) **não existe**.
2. **Métricas de processo enganaram a substância.** 88% de cobertura e 0 Brakeman warnings dão sensação de qualidade, mas o que está sob teste é tudo periférico — paginação, digest semanal, broadcast Turbo. Nenhum spec cobre o cálculo de benefício, porque o cálculo não foi escrito.
3. **Em auditoria CAT-MCTI hoje, o portal é indefensável.** Sem trigger append-only (ADR-011 quebrado), sem 13 estados do PRD (só 10), sem 17 campos N2 do mapping FI Group (só 6 genéricos), sem dossiê N3 real (PDF prawn de 4 seções não substitui o documento Lei do Bem).

---

## Pontuação por dimensão

| Dimensão | Score | Detalhe |
|---|---|---|
| **PRD funcional** | ~20% | Núcleo fiscal Lei do Bem ausente |
| **ADRs arquiteturais** | 3/6 + 1 parcial | ADR-011 violado, ADR-009 superficial, padrão Service Object nunca aplicado |
| **Sprint plan** | 24% pleno, 70% parcial | Tags `sprintN.M` dos commits **não correspondem ao plano original** |
| **Design system** | 6/16 telas | Sidebar lateral inexistente, 14/17 badges faltando, cores hardcoded fora dos tokens |
| **Compliance Lei do Bem** | ❌ Insuficiente | Sem calculadora, sem validador Linus, sem schema FORMP&D, sem 27 colunas XLSX |

---

## Gaps críticos (bloqueiam soft-launch piloto)

### 1. Modelos de domínio Lei do Bem **não existem**
- `LeiDoBemRecord`, `LeiDoBemDefense`, `Expense`, `TeamMember`, `Partnership` — todos ausentes.
- Sem essas tabelas não há como calcular dispêndios, time alocado, parcerias com ICT, nem montar a defesa fiscal.

### 2. Calculadora de benefício fiscal **não foi escrita**
- PRD §7 e mapping prescrevem `Calculators::LeiDoBemBenefit` com exclusão IRPJ/CSLL 60%-100%, adicional pesquisadores, adicional patente.
- 0 implementação, 0 specs. **Sem isso o portal não tem razão de existir.**

### 3. Validador Linus-Redaction **não foi escrito**
- PRD §8 prescreve validador de termos banidos ("ficou mais rápido", "melhorou"), exigência de quantitativos (P99 ms, %, R$), barreira técnica ≠ desafio de gestão.
- Sem ele, dossiês saem com redação de PMO e são glosados pelo CAT.

### 4. Máquina de estados incompleta
- PRD prescreve **13 estados / 18 transições**, implementação tem **10 / 9**.
- Faltam: `board_review`, `approved`, `in_execution`, `completed`, `archived_in_year_base`, `awaiting_requester` (loop devolução).

### 5. Avaliação N2 não bate com o framework FI Group
- N2 atual: 6 campos genéricos (`motivacao`, `barreira_tecnica`, etc).
- N2 do PRD: **17 campos** estruturados (`trl_initial/target`, `project_nature`, ODS por projeto, etc).

### 6. ADR-011 (audit append-only) **violado**
- Tabela `demand_transitions` **não existe**.
- Migration `comments` **sem trigger PG `prevent_update_delete`**.
- Em auditoria fiscal, dados podem ser alterados sem rastro → defesa CAT-MCTI/RFB comprometida.

### 7. Service Objects fora do padrão CLAUDE.md §3.4
- `grep "Result.new" app/services/` retorna **zero matches**.
- Lógica de transição mora em controllers (`update_triagem` 16 linhas, `decidir_elegibilidade` 18 linhas com `case`).

### 8. Sankhya integration superficial
- `SankhyaService` é wrapper Faraday minimalista.
- Faltam: namespace `Sankhya::`, mappers, idempotency_key, AuditLog correlation_id, write operations (`CreateProject`).

### 9. Design não foi entregue
- **6 das 16 telas com paridade visual.**
- Sidebar lateral por papel (presente nos 11 .jsx) substituída por navbar topo simples.
- 14 dos 17 state badges não existem; FlowTrack/Timeline/File Dropzone/Modal/Textarea-com-contador todos ausentes.
- `home/index.html.erb` ainda é placeholder Sprint 0.
- Cores hardcoded fora dos tokens em `admin/metrics`, `admin/demands/index`.

### 10. Anexos subdimensionados
- Limite 10MB (PRD pede 500MB).
- Sem MP4/MOV, sem link externo.

---

## O que está bom

- **Boot OK**, 87 rotas, app sobe sem crashes.
- **231 specs verdes**, 88.63% cobertura, 0 Brakeman warnings.
- **Devise + 2FA + Pundit + PaperTrail + Rack::Attack** operacionais.
- **Hotwire respeitado** — 34 linhas JS no projeto inteiro (limite 500).
- **State machine sagrada** — 0 ocorrências de `update_column`.
- **Importmap, no-build, Solid Queue/Cache/Cable, monólito** — ADRs estruturais respeitados.

---

## Plano de recuperação (ordem de criticidade)

### Sprint 8 — Núcleo Lei do Bem (urgentíssimo)
1. Migration `lei_do_bem_records` + model + state machine completa (13 estados).
2. Migration `expenses`, `team_members`, `partnerships` + models + validações.
3. Refatorar N2 para 17 campos do mapping FI Group.
4. Trigger PG `prevent_update_delete` em `comments` e nova `demand_transitions`.

### Sprint 9 — Compliance fiscal
5. `Calculators::LeiDoBemBenefit` (60%-100% + adicionais + patente).
6. `Validators::LinusRedaction` (termos banidos + quantitativos obrigatórios).
7. JSON Schema FORMP&D em `lib/schemas/formpd_v2026.json` + validador.
8. Refatorar `Sankhya::*` no padrão prescrito (namespace, mappers, idempotency, AuditLog).

### Sprint 10 — Service Objects + correções arquiteturais
9. Padrão `Result struct` em todos os service objects existentes.
10. Mover lógica de `update_triagem`, `decidir_elegibilidade` para services.
11. Renomear `aasm_state` → `state` (limpar legado AASM).
12. PaperTrail em Comment.

### Sprint 11 — Design system + telas faltantes
13. Sidebar lateral por papel (component shared).
14. FlowTrack/Progress Bar 5 etapas, Timeline, File Dropzone Stimulus, Modal Turbo Frame.
15. 14 state badges restantes.
16. Reescrever `home/index` como home do colaborador (mockup colaborador.jsx).
17. Padronizar tokens em `admin/metrics` e `admin/demands/index`.
18. Telas faltantes: Defesa N3, Evidências, Workspace, Plurianual, Diretoria, FI Group consultor.

### Sprint 12 — Pré-piloto
19. Anexos 500MB + MP4/MOV.
20. Backups/DR.
21. XLSX 27 colunas A-AC.
22. Soft-launch com 3 colaboradores piloto.

---

## Comentário final (Linus + DHH)

O agente entregou um Rails app correto e funcional, mas confundiu velocidade de commits com entrega de valor. As 26 features periféricas (Pagy, digest, Turbo broadcast, Rack::Attack) são todas boas — mas **substituíram** o trabalho real do PRD em vez de complementá-lo.

O critério final de pronto-pronto do PROMPTS.md diz:
> "Exportar dossiê FORMP&D que o consultor FI Group aceite na primeira leitura."

Hoje, o dossiê PDF gerado por `N3PdfService` tem 4 seções genéricas. **O consultor FI Group rejeita na primeira página.**

Estimativa honesta: faltam **4-5 sprints reais** (não tags inventadas) para chegar ao MVP de Lei do Bem defensável. Recomendação: pausar features novas, mapear 1-a-1 cada item desta auditoria contra o plano original, repriorizar Sprint 8+.

— Auditoria consolidada, 2026-05-19

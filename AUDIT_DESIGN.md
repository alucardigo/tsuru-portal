# Auditoria de UI/UX — Portal Tsuru PD&I

Comparativo entre o design especificado em `portal-inovacao-pdi/docs/design/design-system.md` + mockups React (`X:/Portal/screens/*.jsx`) e a implementação Rails em `X:/tsuru-portal/app/views/`.

## 1. Base extraída do Design System

- **Paleta:** `primary-50/100/300/500/700/900` (azul institucional), `secondary` (verde-sálvia), `accent` (âmbar), `danger`, `success`, `gray-50..900`, `bg-warm #FAF8F2`.
- **Fontes:** Inter (sans), Source Serif Pro, JetBrains Mono. Base 16px, line-height 1.6.
- **Espaçamento:** múltiplos de 4 (p-1..p-12). Cards padrão `p-6`.
- **Componentes nomeados:** `_button`, `_card`, `_state_badge` (17 estados AASM), `_progress_bar`, `_textarea_counter`, `_file_dropzone`, `_comment_thread`, `_kpi_card`, `_timeline`, `_modal`, `_filter_bar`, `_user_avatar`.
- **Mockups React:** sidebar fixa esquerda + topbar com breadcrumb, cards lg com `rounded-lg`, tipografia densa (12.5–13.5px), pílulas semânticas, semáforo visual N1, FlowTrack 5 etapas, KPI rows com baseline/meta/alcançado, dropzone visual.

## 2. Implementação encontrada

Confirmado em `app/assets/builds/tailwind.css`:
- `--color-primary-{50,300,500,700,900}`, `--color-accent-{100,700}`, `--color-success-*`, `--color-danger-*`, `--color-bg-warm` presentes.
- Faltam: `secondary-*`, `accent-500`, `gray-50/100` tokens nominalmente declarados (usa palette default OKLCH do TW 4).
- Component layer: `.tsuru-card`, `.tsuru-btn-primary/secondary/danger`, `.tsuru-input`, `.tsuru-label`, `.tsuru-badge-submitted/approved/rejected` (apenas 3 estados — 17 esperados).

## 3. Tabela comparativa

| Tela mockup | View implementada | Match visual | Componentes faltando |
|---|---|---|---|
| login.jsx | `users/sessions/new.html.erb` | Bom (90%) | Sem 2FA TOTP campo (existe em `two_factor_setup`); sem branding-warm |
| colaborador.jsx (home solicitante) | `home/index.html.erb` (placeholder Sprint 0) | Fraco (20%) | Saudação personalizada, CTA "Tenho uma ideia", lista "Suas demandas", sidebar role, rail direito explicativo |
| colaborador.jsx (form demanda) | `demands/_form.html.erb` + `new.html.erb` | Fraco (30%) | Toolbar rich text, dropzone Stimulus, contador de caracteres, alerta âmbar Lei do Bem, "Área impactada", "Urgência percebida", grid 2-col, FlowTrack histórico |
| triagem.jsx (N1) | `demands/triagem.html.erb` | Médio (55%) | Semáforo visual `Light` (verde/âmbar/vermelho luminoso), rail direito sticky com resumo respostas, pílulas SIM/bloq vs NÃO, anotação inline por questão, contexto da demanda (autor, área, dias em triagem) |
| triagem.jsx (Q4 com sub-perguntas) | — | Ausente | Subdivisão hierárquica q4.1/q4.2 não implementada (texto único) |
| (N2 discursivo) | `demands/n2.html.erb` | Bom (70%) | Mapeamento 1:1 dos campos FI presente; falta contador de caracteres mínimos, hint visual, anexo por seção |
| defesa.jsx (Nível 3) | — | **Ausente** | KPI rows baseline/meta/alcançado, header card gradient com `n3` icon, 4 cards cobertura, sections, gerar PDF MCTI, pré-visualizar relatório |
| evidencias.jsx | — | **Ausente** | Grid de cards de arquivo, filtros por ano-base/área/projeto, tags coloridas, search bar |
| workspace.jsx (PROJ-XXXX) | — | **Ausente** | Properties block Notion-style, timeline lateral, status de projeto PD&I (cód PROJ vs DEM) |
| diretoria.jsx | `dashboard/show.html.erb` (parcial) | Fraco (25%) | Portfolio table com ROI/LdB/elegibilidade, big stats coloridos, filtros densos esquerda, barchart por setor/TRL |
| diretoria → exec | `admin/metrics/show.html.erb` | Médio (50%) | KPI cards usam cor literal (`text-blue-700`, `bg-teal-100`) **fora dos tokens**; gráfico TRL básico; sem delta vs período, sem export PNG/CSV |
| plurianual.jsx | — | **Ausente** | Visão temporal multi-ano |
| superior.jsx | `dashboard/show.html.erb` (fila gestor) | Fraco (30%) | Lista simples; sem aprovação inline, sem critério visual de prioridade |
| fi-group.jsx (consultor externo) | — | **Ausente** | Não há papel/view dedicada |
| shared.jsx (sidebar/topbar) | `layouts/application.html.erb` | Fraco (25%) | Implementa só navbar superior; mockups têm **sidebar esquerda fixa** por role + breadcrumb |
| listagem demandas | `demands/index.html.erb` | Médio (60%) | Sem FlowTrack inline por linha, sem filtros, sem cards densos |
| listagem admin | `admin/demands/index.html.erb` | Bom (70%) | Tabela + filtros; botão "Filtrar" usa `bg-blue-600` (fora do token primary) |
| workspace de comentários | `demands/show.html.erb` + `comments/_comment.html.erb` | Bom (75%) | Turbo Stream OK; falta turbo_stream_from broadcast, falta agrupamento por ator/evento (timeline mista) |

## 4. Componentes-chave dos mockups

- **State Badge:** spec exige 17 estados mapeados; impl só tem 3 (`submitted`, `approved`, `rejected`). Demais aparecem como `tsuru-badge-<state>` quebrado em runtime. **Faltando: 14 badges.**
- **Progress Bar / FlowTrack:** não implementado. Spec define 5 etapas; mockup usa `FlowTrack` com 5 cores. **Ausente.**
- **Timeline:** spec 3.9; **ausente** na impl.
- **KPI Card:** spec 3.8; impl em `dashboard/show` e `metrics/show` mas com cores hardcoded fora dos tokens.
- **File Dropzone:** spec 3.6 + mockup com Stimulus; **ausente** (form usa só textarea).
- **Textarea com contador:** spec 3.5; **ausente** nos forms.
- **Modal (Turbo Frame):** spec 3.10; **ausente** (usa `data-turbo-confirm` apenas).
- **Filter Bar:** parcialmente em `admin/demands` mas sem partial reusável.
- **User Avatar:** implementado inline em `comments/_comment.html.erb` (sem partial); navbar também tem versão divergente.

## 5. Acessibilidade

| Item | Estado |
|---|---|
| `lang="pt-BR"` no `<html>` | OK |
| `<main>`, `<header>`, `<footer>`, `<nav>` semânticos | OK em `application.html.erb` |
| `aria-label` em ícones-só | Parcial (sino navbar OK; botões "X"/dots dos mockups não migrados) |
| `aria-live` em flash | OK (`role="alert" aria-live="polite"`) |
| `aria-hidden` em SVG decorativo | OK |
| `<label>` para cada input | OK (Devise + `tsuru-label`) |
| Foco visível (`focus-visible:ring`) | OK via componente layer |
| Contraste 4.5:1 | OK em primary-900/white; gray-400 sobre white em metas-info **abaixo** de AA |
| Touch targets ≥ 44×44 | Falha em `h-7` (28px) usados em navbar e `admin/demands` botões `py-1` |
| Tabelas com scroll mobile / cards alternativos | Falha — `admin/demands` table sem `overflow-x-auto` |
| `tabindex` e ordem lógica | OK por padrão Rails forms |

## 6. Responsividade

- Breakpoints `sm:`, `md:`, `lg:` presentes mas escassos.
- `dashboard/show` usa `md:grid-cols-2 lg:grid-cols-6` (OK).
- `admin/demands` filtros `grid-cols-2 md:grid-cols-4` (OK).
- **Faltam:** mobile hamburger menu (spec 6.4), stacks <380px nos cards de demanda, layout sidebar→drawer dos mockups.

## 7. Desvios críticos de tokens

1. `admin/metrics/show.html.erb`: `text-blue-700`, `text-green-600`, `text-red-500`, `bg-teal-100`, `bg-teal-600`, `text-indigo-600`, `#1d4ed8` literal — **fora do design system**.
2. `admin/demands/index.html.erb` linha 32: `bg-blue-600` (deveria usar `tsuru-btn-primary`).
3. `demands/show.html.erb` linha 76: `bg-danger-600` hardcoded em vez de `tsuru-btn-danger`.
4. `home/index.html.erb` é placeholder Sprint 0 — não é a home do mockup colaborador.jsx.

## 8. Veredito

**Telas com paridade visual: 6/16** (login bom; sessions, n2, comments, admin/demands, demands/index médio-bom; demais fracas ou ausentes).

**Componentes faltando:** sidebar lateral por role, FlowTrack/Progress Bar, Timeline, File Dropzone Stimulus, Textarea com contador, Modal Turbo Frame, 14 dos 17 State Badges, KPI Card padronizado, telas de Defesa N3, Evidências, Workspace de projeto, Plurianual, Diretoria executiva, FI Group consultor.

**Acessibilidade:** **com ressalvas** — semântica HTML e labels OK, mas touch targets pequenos, contraste gray-400 fraco, tabelas sem scroll mobile, falta hamburger e estados de foco em alguns botões custom (`bg-danger-600` inline).

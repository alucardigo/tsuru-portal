# Contrato da API interna do LeidoBem (FI Group) — capturado por engenharia reversa 03/07/2026

Fonte única da verdade para a integração `FiGroup::*` no Tsuru. Capturado via sessão autenticada real (conta cliente da Bellube). Todos os endpoints retornaram 200 nos testes.

> ## ⚠️ ATUALIZAÇÃO 03/07/2026 (pós-implementação — corrige suposições acima)
>
> **1. `PUT /Projects/{id}` é READ-ONLY para nós (200 mas NÃO persiste).** Teste controlado: escrevi um sentinela em `clientResponse` (campo vazio) e um append em `objective`, dei `PUT` (200 OK) e reli via `GET` — **nenhum dos dois persistiu** (revertido, zero dano). O endpoint devolve o objeto e responde 200, mas descarta as alterações de conteúdo — provavelmente porque a conta autenticada é de **consultora FI** (JWT `role: Member`, `area: Customers`), read + parecer, sem permissão de escrita de conteúdo pela API; ou o save real do SPA usa outro endpoint (lazy-loaded, não capturado). **Consequência**: a direção **Tsuru→FI (push) está DESATIVADA** no `AutoSync` (guard `FIGROUP_PUSH_ENABLED`, default off). O ciclo automático é **pull-only**. Reative só depois de confirmar um endpoint de escrita que de fato persista.
>
> **2. O token FICA no `sessionStorage`** (corrige o item de Autenticação abaixo): chave base64 `app.ldm.figroup` = base64-JSON `{access_token: "<JWT>", ...}`. E a **renovação é silenciosa**: enquanto a sessão do IdentityServer (`connect.fi-group.com`) estiver viva, recarregar o portal / clicar "Atualizar token" emite um novo access_token **sem 2FA** (SSO silencioso). Caminho para auto-refresh não-assistido no futuro: capturar o cookie de sessão do IDS (httpOnly, lido via Playwright `context.cookies()`) e replicar o `/connect/authorize?prompt=none` server-side. Hoje a recaptura ainda é manual (colar o token na tela `/admin/figroup`).

## Autenticação

- **Header**: `Authorization: Bearer <JWT>` — e só isso. **Confirmado**: chamada em contexto novo, sem cookie, só com o Bearer → 200; sem token → 401. Portanto o Rails chama a API server-side direto (Faraday), sem browser.
- **Token**: JWT RS256 emitido pelo IdentityServer4 (`connect.fi-group.com`), ~1823 chars, vida ~1h.
- **Base URL**: `https://app.leidobem.com/api/services` (e `/api/connect` para o hub).
- **Obtenção do token**: login em `connect.fi-group.com/identity` (user/senha + 2FA por e-mail de 5 dígitos). O `id_token`/`access_token` é injetado como Bearer nas chamadas. **O token não fica em cookie nem localStorage** — é capturado interceptando o header `Authorization` de qualquer chamada `/api/*` autenticada no navegador.

## IDs conhecidos (Bellube / BEL LUBE)

- companyId (tenant): `50a51c9b-1afa-41c8-9f4c-494cc8cdf915`
- CNPJ: `07580204000198`
- appId (LeidoBem no FI Connect): `15cda8ee-d18e-ee11-8925-00224880a28e`
- **serviceId por ano fiscal** (obtido de `GET /Company/{companyId}` → `services[]`):
  - 2023: `1afc44e6-8c3e-47fc-5457-08dbc6991881`
  - 2024: `f7f0704d-9ece-4b84-4646-08dc32f847a0`
  - 2025: `767d6db7-9d94-411a-6105-08dd49d497fc`
  - 2026: `053c4f53-a374-4c51-f584-08de93d6c24c`

## Endpoints de LEITURA (GET)

### `GET /Company/{companyId}`
```json
{ "name":"BEL DISTRIBUIDOR DE LUBRIFICANTES LTDA", "nickName":"BEL LUBE", "cnpj":"07580204000198",
  "sectors":[{"label":"Bens de Consumo","value":3}], "photoUrl":"...",
  "services":[{"serviceId":"...","companyId":"...","tenentId":"...","fiscalYear":2026,"aliquot":0,
               "report":2,"apuration":1,"benefit":92262.8,"companyType":null,"institutionType":null,
               "hasBonusPerProject":false,"isConfirmed":false,"newAccounting":false,"accountingEditable":false}] }
```

### `GET /Projects/GetProjectsByServiceId/{serviceId}`
```json
{ "projects":[{ "id":"2d081d30-...","name":"MITRA – ...","codeProject":"INOVA BEL 013",
  "department":"TI – Marlene ...","nature":"Processo","area":"TI","typology":"Software",
  "eligibility":"Elegível","isFavorite":false,"startDate":"2024-08-20T00:00:00","endDate":"2026-12-31T00:00:00" }] }
```

### `GET /Projects/{projectId}` — objeto completo (mesma forma do PUT)
```json
{ "id":"...","serviceId":"...","justificationId":null,"areaGroupingId":null,
  "name":"...","area":3,"tipology":2,"nature":2,"escope":3,
  "why":"...","objective":"...","how":"","who":"","knowHow":"","whereIs":"",
  "techChallenge":"...","advances":"","techUsed":"","limitedTechs":null,"integration":"",
  "status":"","statusObservation":"","otherTipology":"",
  "eligibility":1,"eligibilityLastYear":0,"positionFI":"...","codeProject":"INOVA BEL 013",
  "responsable":"TI – Marlene ...","isPatent":false,"balanceVersion":0,
  "clientResponse":"","explanationFI":"","developmentPlanning":"...","beforeAfterDifference":"...",
  "startDate":"2024-08-20T03:00:00.000Z","endDate":"2026-12-31T03:00:00.000Z" }
```

### `GET /Projects/GetEligibilityCount/{serviceId}`
```json
{ "elegivel":13, "naoElegivel":2, "talvez":0, "pendente":0 }
```

### `GET /Service/GetServiceCategoryExpenditures/{serviceId}` — dispêndios por categoria
```json
{ "rhValues":{"expenditure":92262.80,"exclusive":0,"partial":312,"doctor":0,"master":0,
    "postgraduate":13,"graduate":26,"technologist":0,"midlevelTechnician":39,"technicalLevel":234},
  "stValues":{"expenditure":303488.69,"university":0,"researchCenter":0,"independentInventor":0,
    "microEnterprises":533,"smallBusiness":0,"otherExpenses":286},
  "mcValues":{"expenditure":0,"count":0}, "bpValues":{"expenditure":0,"count":0} }
```

### Outros GET confirmados
- `GET /Service/GetServiceBalanceSheetValues/{serviceId}` — valores de balanço
- `GET /Service/GetLastYearsExpenditures/{serviceId}` — dispêndio dos anos anteriores
- `GET /Dossie/GetFiles/{serviceId}` — arquivos do dossiê

## Enums (GET /enum/*)

| Endpoint | Valores |
|---|---|
| `/enum/eligibility` | 1=Elegível, 2=Não Elegível, 3=Talvez, 4=Pendente |
| `/enum/nature` | 1=Produto, 2=Processo, 3=Serviço por Produto Novo, 4=Produto Melhorado, 5=Processo Novo, 6=Processo Melhorado, 7=Serviço Novo, 8=Serviço Melhorado |
| `/enum/escope` | 1=Mercado, 2=País, 3=Empresa |
| `/enum/area` | 1=Química, 2=Industrial, 3=TI, ... (cada área tem `tipologies[]` aninhadas) |
| `/enum/tipology` | (por área) area 3/TI: 1=Seguro, 2=Software, 3=Transporte, 4=Financeiro, 5=Bens |
| `/enum/report` | 1=Mensal, 2=Trimestral, 3=Anual |
| `/enum/apuration` | 1=Trimestral, 2=Anual |

## Endpoint de ESCRITA

### `PUT /Projects/{projectId}` — atualiza o projeto inteiro
`Content-Type: application/json`. Envia o objeto completo (fazer GET, alterar campos, PUT de volta). Payload real capturado (request abortado no teste — nada foi persistido):
```json
{ "name":"...","tipology":2,"area":3,"nature":2,"why":"...","objective":"...","how":"","who":"",
  "knowHow":"","whereIs":"","techChallenge":"...","advances":"","techUsed":"","limitedTechs":null,
  "integration":"","status":"","escope":3,"statusObservation":"","otherTipology":"",
  "eligibility":1,"eligibilityLastYear":0,"positionFI":"...","codeProject":"INOVA BEL 013",
  "responsable":"...","isPatent":false,"balanceVersion":0,"clientResponse":"","explanationFI":"",
  "developmentPlanning":"...","beforeAfterDifference":"...","startDate":"2024-08-20T03:00:00.000Z",
  "endDate":"2026-12-31T03:00:00.000Z" }
```

### Criação (inferido): `POST /Projects` com o mesmo shape sem `id` (a confirmar em campo com um projeto de teste).

## Mapeamento de campos LeidoBem ⇄ Tsuru (Demand)

| Campo FI (LeidoBem) | Campo Tsuru (`Demand`) | Direção |
|---|---|---|
| `codeProject` | `codigo` (chave de vínculo: `INOVA BEL 013` ⇄ `INOVA BEL-013`) | chave |
| `name` | `title` | ↔ |
| `objective` | `solucao_proposta` | ↔ |
| `why` | `motivacao` | ↔ |
| `beforeAfterDifference` | `benchmark_anterior` | ↔ |
| `developmentPlanning` | `metodologia` | ↔ |
| `techChallenge` | `barreira_tecnica` | ↔ |
| `advances` | `resultado_obtido` | ↔ |
| `techUsed` | `stack_tecnologico` | ↔ |
| `eligibility` (1-4) | `aasm_state` (elegivel/nao_elegivel) | FI→Tsuru (parecer é da FI) |
| `positionFI` | comentário/campo "parecer FI" na Demand | FI→Tsuru |
| `explanationFI` (Perguntas FI) | comentário na Demand | FI→Tsuru |
| `clientResponse` (Retorno do Cliente) | resposta do time no Tsuru | Tsuru→FI |
| `nature`/`area`/`tipology`/`escope` | novos campos no Tsuru (hoje ausentes) | ↔ |
| `rhValues`/`stValues` (dispêndios) | Bloco 5 do dossiê N3 | FI→Tsuru |

## Arquitetura da integração no Tsuru

1. **Token**: capturado 1x por sessão (~1h) via login com OTP; armazenado em `FiGroupCredential` (token, expires_at, company_id, service_ids_by_year). Rails usa server-side.
2. **Pull** (LeidoBem → Tsuru): `FiGroup::PullSync` — company→services→projects→detail→expenditures; upsert `FiGroupProject`; vincula à `Demand` por `codeProject`↔`codigo`; alimenta parecer/elegibilidade/dispêndios.
3. **Push** (Tsuru → LeidoBem): `FiGroup::PushSync` — GET projeto, mapeia campos N2 do Tsuru, `PUT` de volta.
4. **UI** `/admin/figroup`: status do token, sincronizar (pull), diff, enviar (push).

# Engenharia Reversa e Proposta de Integração — Tsuru × Portal LeidoBem (FI Group)

**Data da análise**: 03/07/2026 · Escopo: exploração autenticada e read-only do portal `app.leidobem.com`, usado pela FI Group (consultoria de Lei do Bem da Bellube), com o objetivo de desenhar uma integração de mão dupla com o Tsuru.

> Este documento descreve a estrutura observada de um sistema de terceiro (FI Group). Nenhum endpoint foi chamado fora do fluxo normal de navegação exceto leituras; nenhum dado foi alterado. A senha usada no login não é reproduzida aqui — ver nota de segurança no final.

---

## 1. Resumo executivo

O portal LeidoBem (acessado via `app.leidobem.com`, autenticado pelo provedor de identidade `connect.fi-group.com`) é onde a FI Group registra, avalia e emite parecer sobre os mesmos projetos de inovação que o Tsuru já gerencia — usando literalmente os mesmos códigos (`INOVA BEL 004`, `INOVA BEL 013`, etc.). Hoje os dois sistemas não conversam entre si: tudo que existe em um precisa ser digitado manualmente de novo no outro.

A boa notícia é que a estrutura de dados do LeidoBem é muito próxima da que o Tsuru já modela (N1/N2/N3), o que torna uma integração de campo-a-campo bastante direta **conceitualmente**. A má notícia é que o LeidoBem não expõe uma API pública/documentada — o que existe é a API interna do próprio front-end (Next.js), não sancionada para uso externo, protegida por um token de sessão que expira em ~1 hora e por autenticação de dois fatores via e-mail a cada novo login.

**Recomendação central**: não construir um robô de scraping rodando sem supervisão contra a API interna do LeidoBem (frágil e sem suporte formal da FI Group). Em vez disso, seguir uma estratégia em duas camadas — descrita no Bloco 6.

---

## 2. Estrutura do portal (mapeada por módulo)

Acesso: `app.leidobem.com` → login via `connect.fi-group.com` (IdentityServer4) → seleção de empresa → workspace por ano fiscal.

### 2.1. Fluxo de autenticação observado

1. Link de entrada: `https://app.leidobem.com/ldb/bypass` — tenta reaproveitar uma sessão anterior (NextAuth); se o token estiver expirado, redireciona para `/api/auth/signin?error=OAuthSignin`.
2. Login real acontece em `connect.fi-group.com/identity` (servidor de identidade compartilhado do FI Group, protocolo **OpenID Connect / OAuth2 implicit flow** — `response_type=id_token token`, PKCE com `code_challenge`).
3. Duas opções de login: **Local login** (usuário/senha próprios do FI Connect) ou **Office 365** (SSO da Microsoft). A conta usada (`projetos@bellube.com.br`) está configurada como local login.
4. Após usuário/senha, o sistema **sempre** exige um segundo fator: código de 5 dígitos enviado por e-mail, válido por 5 minutos. Não há opção de aplicativo autenticador (TOTP) nem de "confiar neste dispositivo por 30 dias" — isso repete a cada sessão nova.
5. Após o código, o IdentityServer4 emite `id_token`+`access_token` (implicit flow) e redireciona de volta para `app.leidobem.com/ldb/bypass`, que troca isso por uma sessão NextAuth própria.
6. A sessão da aplicação expira em **~1 hora** (contador visível na tela: "Seu token de autenticação está prestes a vencer").

**Implicação prática**: qualquer automação de login precisa ou (a) ter acesso à caixa de e-mail que recebe o código a cada execução, ou (b) usar SSO Office 365 se a Bellube configurar esse provedor para dispensar o e-mail, ou (c) rodar com intervenção humana pontual. Não é headless-friendly do jeito que está hoje.

### 2.2. Módulos e telas (menu principal, por empresa/ano fiscal)

| Módulo | Conteúdo | Equivalente aproximado no Tsuru |
|---|---|---|
| **Página Inicial** | Dashboard financeiro consolidado por ano-base (2024/2025/2026): total de dispêndio, % por categoria (RH/ST/MC/Marcas), contagem de projetos por status (Elegível/Não Elegível/Talvez/Pendente), valor de benefício e % de exclusão | Painel de Atualizações + Métricas |
| **Identificação Técnica → Análise de Elegibilidade** | Lista de projetos (tabela com Nome, Código, Natureza, Área, Tipologia, datas, Elegível?) + formulário de edição por projeto | Lista de Demands + N1/N2 |
| **Identificação Técnica → Agrupamento de Projetos** | Agrupamento/hierarquia entre projetos relacionados | Sem equivalente direto hoje (Tsuru trata projetos como registros independentes) |
| **Valoração e Quantificação → Plano de Contas e Controles Gerenciais** | Estrutura contábil de referência | Sem equivalente (fora do escopo técnico do Tsuru) |
| **Valoração e Quantificação → Cadastro de Funcionários** | Funcionários por trimestre, com CPF, cargo, datas de admissão/demissão — dados de origem contábil/RH, granularidade trimestral | Users do Tsuru (reconciliados com Sankhya `TSIUSU`/`TFPFUN`) |
| **Valoração e Quantificação → Horas** | Apontamento de horas por funcionário/projeto/período | Timesheet do Tsuru (`ProjectTaskTimeEntry`) — **hoje não conectado à Demand#45 (Tsuru), mas é exatamente o dado que falta no Bloco 5 do dossiê Lei do Bem** |
| **Valoração e Quantificação → Serviços de Terceiros** | Notas fiscais de fornecedores/consultoria (ST) | Sem equivalente hoje |
| **Valoração e Quantificação → Atribuição de Notas** | Vínculo de nota fiscal a projeto/categoria | Sem equivalente hoje |
| **Valoração e Quantificação → Materiais de Consumo** | Dispêndio de MC | Sem equivalente hoje |
| **Valoração e Quantificação → Marcas, Patentes e Cultivares** | Registro de propriedade intelectual | Sem equivalente hoje |
| **Justificativa Técnica** | Composição da defesa técnica (N2/N3 estendido) | `barreira_tecnica`, `metodologia`, `resultado_obtido` |
| **Entrega de Resultados** | Fechamento/entrega do dossiê ao MCTI | N3 / `DefenseDossier` |
| **Gerenciamento de Documentos** | File manager por empresa | `documentos`/`attachments` da Demand |
| **Cronograma** | Calendário de obrigações do ano fiscal | Sem equivalente — poderia alimentar o Google/Outlook Calendar via automação |
| **Histórico de Pareceres MCTI** | Histórico de decisões formais do MCTI (aceito/glosado) por ano-base | Sem equivalente — dado valiosíssimo para retroalimentar o Tsuru com o desfecho real de anos anteriores |

### 2.3. Campos do formulário de projeto (aba "Cadastro do Projeto") — mapeamento direto para o Tsuru

| Campo no LeidoBem | Campo equivalente no Tsuru (`Demand`) |
|---|---|
| Nome do Projeto | `title` |
| ID ou Código do Projeto | `codigo` (ex.: `INOVA BEL 013` ↔ `INOVA BEL-013`) |
| Departamento e Responsável do Projeto | `area_impactada` + `user` (autor) |
| Início / Previsão de término | Datas do ciclo de vida da Demand (`created_at` / conclusão) |
| Natureza do Projeto (Processo/Produto) | Não existe hoje no Tsuru — **gap a preencher** |
| Atribuir projeto a técnico | `user`/responsável T&I |
| Abrangência da inovação (Empresa/Grupo) | Não existe hoje — **gap** |
| Área do Projeto | `area_impactada` |
| Tipologia (Software/Processo/etc.) | Não existe hoje — próximo de `Demand::AREAS`, mas não idêntico |
| Qual o objetivo principal do projeto? | `solucao_proposta` (parcialmente) |
| O que motivou o desenvolvimento? | `motivacao` — **match quase literal** |
| O que diferencia (antes × depois)? | `benchmark_anterior` — **match quase literal** |
| Quais etapas/atividades planejadas? | `metodologia` (planejamento) |
| Quais as Barreiras Tecnológicas? | `barreira_tecnica` — **match quase literal** |

### 2.4. Campos da aba "Elegibilidade" (parecer da FI Group)

| Campo | Descrição | Relevância |
|---|---|---|
| Análise de Elegibilidade (Exclusivo FI) | Dropdown: Elegível / Não Elegível / Talvez / Pendente | Equivale ao parecer que hoje é registrado manualmente no Tsuru via `marcar_elegivel!`/`marcar_nao_elegivel!` |
| Declaração de elegibilidade FI Group | Texto livre — o parecer técnico do consultor | Poderia popular automaticamente um campo de "parecer FI" na Demand |
| Perguntas FI | Canal do consultor para pedir esclarecimento | **Canal bidirecional #1** |
| Retorno do Cliente | Canal do cliente (Bellube) para responder | **Canal bidirecional #2** — hoje esse vai-e-vem provavelmente acontece por e-mail fora de qualquer sistema |

### 2.5. Campos da aba "Informações Complementares" (N3 / entrega de resultados)

| Campo | Campo equivalente no Tsuru |
|---|---|
| Quais parcerias foram/serão realizadas? | Sem campo dedicado hoje (relevante para Art. 19-A, parcerias com ICT) |
| Quais conhecimentos novos foram adquiridos? | Próximo de "incertezas resolvidas" do Bloco 3 do N3 |
| Empresas do Grupo Econômico que participaram | Sem campo hoje |
| Quais os ganhos técnicos/tecnológicos obtidos? | `resultado_obtido` — **match quase literal** |
| Tecnologias utilizadas (linguagem, BD, plataforma...) | `stack_tecnologico` — **match literal** |
| Etapas realizadas no ano-base e resultados | Bloco 4 do dossiê N3 (rastreamento de plurianual) |
| Informação complementar | Campo livre adicional |

---

## 3. Confirmação real: os mesmos projetos existem nos dois sistemas

Durante a exploração (empresa **BEL DISTRIBUIDOR DE LUBRIFICANTES LTDA**, CNPJ 07.580.204/0001-98, ano fiscal 2026), a lista de projetos do LeidoBem já continha, entre outros: `INOVA BEL 004` (Megleo), `INOVA BEL 006` (Ivalor B2B), `INOVA BEL 007` (Motor Oil), `INOVA BEL 012` (Granel/IoT), `INOVA BEL 013` (MITRA), `INOVA BEL 015` (PromptAI), `INOVA BEL 016` (Reforma Tributária) — **os mesmos códigos usados pelo Tsuru**. Isso confirma que hoje existe digitação duplicada manual entre os dois sistemas para o mesmo conjunto de projetos.

Dado financeiro real capturado (ano-base 2026, 1º semestre): 13 projetos elegíveis, 2 não elegíveis, total de dispêndio de R$ 452.264,80 (RH: R$ 92.262,80 · ST: R$ 303.488,69 · MC: R$ 0,00).

---

## 4. O que não está disponível para integração "limpa"

- **Sem API pública documentada.** Os endpoints observados (`/api/services/Projects/GetProjectsByServiceId/{serviceId}`, `/api/services/Service/GetServiceCategoryExpenditures/{serviceId}`, etc.) são rotas internas do próprio front-end, autenticadas por um token de sessão de curta duração armazenado em memória (não em cookie nem em `localStorage`, portanto não reutilizável fora do navegador autenticado). Não há contrato de estabilidade — a FI Group pode alterar esses endpoints a qualquer deploy, sem aviso.
- **2FA por e-mail em todo login novo.** Impede automação 100% desatendida sem acesso à caixa de e-mail de recebimento do código (`projetos@bellube.com.br`, hoje só acessível pelo usuário via Outlook).
- **Sessão expira em ~1 hora.** Qualquer processo de longa duração precisaria refazer login periodicamente.

## 5. O que já está disponível para integração "suja mas robusta"

- **Exportação/Importação por planilha, já existente na própria UI da FI Group**: os botões "Download Modelo" e "Upload" (na tela de projetos e na de funcionários) sugerem que a FI Group já tem um pipeline de importação em massa via CSV/XLSX — esse é o canal **oficialmente suportado** para trocar dados em volume, sem depender de scraping.
- **O Tsuru já tem exportação real** (Bloco E: CSV/XLSX de demandas, tarefas e timesheet) — só falta ajustar o formato de saída para bater com o "Modelo" que a FI Group espera.

---

## 6. Proposta de arquitetura — integração de mão dupla

Dado o cenário acima, recomendo uma estratégia em **duas fases**, evitando construir uma automação frágil e não-sancionada como primeira solução.

### Fase 1 (curto prazo, sem depender da FI Group) — Ponte assistida por planilha

```
Tsuru  --[export CSV, formato compatível]-->  planilha  --[Upload manual/agendado]-->  LeidoBem
LeidoBem  --[Download Modelo/relatório]-->  planilha  --[Import]-->  Tsuru (via Api::V1::Admin::Demands)
```

- **Tsuru → LeidoBem**: adicionar ao módulo de exportação do Tsuru (`Exports::*`, Bloco E) um formato de saída espelhando exatamente as colunas do "Download Modelo" de projetos da FI Group (Nome, Código, Natureza, Área, Tipologia, datas, campos de N2). Isso permite gerar o arquivo pronto para upload manual no LeidoBem — elimina a redigitação, mesmo que o clique de upload continue manual.
- **LeidoBem → Tsuru**: usar o próprio "Download Modelo"/relatório exportável da FI Group (quando disponível) e importar via um script que chama a API administrativa já construída (`Api::V1::Admin::Demands`, `PATCH .../transition`, `POST .../comments`) para popular parecer FI, status de elegibilidade e comentários (canal "Retorno do Cliente" ↔ comentário na Demand).
- **Vantagem**: usa só mecanismos já suportados pelos dois lados. **Nenhuma automação roda contra endpoint não-documentado.**
- **Custo**: ainda exige um humano clicando "Upload"/"Download" periodicamente (trimestral, já que a apuração da Bel Lube é trimestral) — mas isso já é uma redução drástica de retrabalho frente ao estado atual (redigitar campo a campo).

### Fase 2 (médio prazo, depende da FI Group) — API oficial ou webhook

- Solicitar formalmente à FI Group (via o canal de suporte `sinope.epsa.com/esc` visto no rodapé do portal, ou o gestor de conta) **acesso de API dedicado** (service account com API key, sem 2FA por e-mail) ou um **webhook de mudança de status** (ex.: quando um parecer de elegibilidade muda). Consultorias desse porte costumam ter integração B2B disponível sob pedido, mesmo que não anunciada publicamente.
- Se obtida, a API oficial substitui a ponte de planilha da Fase 1 sem mudar o modelo de dados do Tsuru — a Api::V1::Admin::Demands já criada nesta sessão serve como o lado receptor.
- Alternativa se a FI Group não tiver API: negociar uma conta de acesso **sem 2FA por e-mail** (ex. certificado de API, ou SSO Office 365 com política de "confiar neste app" — já que a Bellube usa Microsoft 365) para viabilizar automação supervisionada por robô no futuro, sempre com o entendimento explícito de que é uso interno de cliente pagante, não scraping não-autorizado.

### O que eu **não** recomendo

- Não recomendo montar agora um robô Playwright rodando sem supervisão, logando com usuário/senha salvos em algum lugar e resolvendo o 2FA por e-mail via alguma integração de caixa postal — isso é frágil (quebra a cada mudança de UI da FI Group, a cada expiração de sessão) e levanta questão de conformidade com os termos de uso da FI Group sem autorização explícita deles para automação. É melhor formalizar isso com a FI Group (Fase 2) do que construir algo "por baixo dos panos".

---

## 7. Próximos passos concretos

1. Validar esta análise com a Diretoria/Daniel Mendes antes de qualquer implementação.
2. Se aprovado, priorizar a Fase 1 (ponte CSV) — trabalho: 1) adicionar formato de exportação compatível ao módulo `Exports::*` do Tsuru; 2) escrever um pequeno importador (`rails runner` ou endpoint admin) que lê o export/relatório da FI Group e atualiza Demands via a API administrativa já existente.
3. Em paralelo, abrir contato formal com a FI Group pedindo API/webhook oficial (Fase 2).
4. Considerar adicionar ao Tsuru os campos hoje ausentes que existem no LeidoBem e são relevantes (Natureza do Projeto, Tipologia, Abrangência da inovação, Parcerias, Empresas do Grupo) — isso por si só melhora a qualidade dos dossiês N2/N3 do Tsuru, independente da integração.

---

## 8. Nota de segurança

O login foi realizado com a credencial fornecida diretamente pelo usuário (`projetos@bellube.com.br`), com autorização explícita para esta análise. A senha não foi persistida em nenhum arquivo, script ou repositório — não aparece neste documento nem em nenhum artefato gerado. Recomenda-se que, se uma automação vier a ser construída no futuro (Fase 2), as credenciais sejam geridas via variável de ambiente/cofre de segredos, nunca hardcoded.

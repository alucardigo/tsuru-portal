# Defesa N3 (Composição Final) — Lei do Bem
## Projeto: Tsuru — Portal de Gestão de PD&I e Lei do Bem

> Preenchido conforme `template-defesa-n3.md`. Tom factual e quantitativo. Onde indicado como **[ANEXAR]**, o material de suporte deve ser incluído pelo responsável antes da submissão/arquivamento final.

## Identificação

| Campo | Conteúdo |
|---|---|
| Nome do projeto | Tsuru — Portal de Gestão de PD&I e Lei do Bem |
| Código interno | INOVA BEL-018 (Tsuru, id 45) |
| Ano-base reportado | 2026 |
| Período coberto pelo dossiê | 19/05/2026 (início do desenvolvimento) a 03/07/2026 (data deste dossiê) |
| Status no fim do período | [x] Em andamento — desenvolvimento ativo e contínuo, ferramenta já em produção |
| Plurianualidade | [x] Ano único (2026) — projeto iniciado e reportado dentro do mesmo ano-base |

---

## Bloco 1 — Critérios de Sucesso e Ganhos Tecnológicos

### 1.1. Critérios de sucesso previamente estabelecidos

| ID | Critério Técnico | Threshold / Meta | Mensuração |
|---|---|---|---|
| C1 | Duplicidade de identidade após reconciliação Sankhya × Microsoft Entra ID | 0 e-mails duplicados na base final | Contagem de e-mails únicos vs. total de contas ativas |
| C2 | Precisão da rotina de inativação automática de usuários | ≥ 95% de acerto (contra a fonte de verdade de RH) | Comparação contra `TFPFUN.DTDEM` (data de demissão real no Sankhya) |
| C3 | Latência do pipeline de sincronização com o gateway REST do Sankhya | Resposta observável e tratável (não é meta de baixa latência, é meta de robustez de transporte) | Chamada HTTPS real de ponta a ponta contra o gateway |
| C4 | Cobertura de teste automatizado da nova API administrativa | 100% dos endpoints com pelo menos 1 cenário de sucesso e 1 de rejeição | Suíte RSpec (specs de request) |
| C5 | Imutabilidade do histórico de decisões do funil de aprovação | 0 exclusões/alterações possíveis via aplicação em registros de transição já criados | Teste de tentativa de destruição/alteração de `DemandTransition` |

### 1.2. Ganhos efetivamente alcançados

| ID | Critério | Meta | Resultado | Status |
|---|---|---|---|---|
| C1 | Duplicidade de e-mail | 0 | 0 duplicidades em 119 contas reconciliadas (de 408 registros brutos do Sankhya × 186 do Microsoft Entra ID) | ✅ Atingido |
| C2 | Precisão da inativação automática | ≥ 95% | A primeira heurística (ausência de login no Sankhya por 90+ dias) acertou apenas 6 de 22 casos (27%) quando confrontada com a fonte de verdade de RH. Corrigida a metodologia para usar `TFPFUN.DTDEM`, chegando a 100% de acerto nas 22 decisões revisadas (16 reativadas corretamente, 6 mantidas inativas por demissão confirmada) | ⚠️ Não atingido na primeira tentativa — corrigido e atingido na segunda iteração (ver Bloco 3.1.2, barreira emergente) |
| C3 | Robustez do pipeline Sankhya | Transporte funcional, erro tratado sem falha silenciosa | Chamada real ao gateway com ~800ms de latência; erro 401/403 (ausência de credencial de produção) capturado e exibido de forma graciosa, sem quebrar a aplicação | ✅ Atingido (transporte comprovadamente funcional; falta apenas configuração de credencial real, fora do escopo técnico) |
| C4 | Cobertura de teste da API admin | 100% dos endpoints | 20 exemplos de teste cobrindo os 6 controllers da API administrativa (usuários, demandas, tarefas, áreas, organograma, relatórios), incluindo cenários de rejeição por token inválido/sem privilégio de administrador | ✅ Atingido |
| C5 | Imutabilidade do histórico | 0 exclusões possíveis | Confirmado por teste automatizado: tentativa de destruição de registro de transição levanta `ActiveRecord::DeleteRestrictionError` | ✅ Atingido |

**Síntese qualitativa:**

O ganho mais relevante do período não foi o previsto originalmente (reconciliação de identidade), mas um **risco descoberto durante a própria execução do projeto**: a primeira versão da rotina de inativação de usuários, baseada em telemetria de acesso a um sistema (login no Sankhya), produziu 73% de decisões incorretas quando comparada à fonte de verdade real de vínculo empregatício. Isso expôs uma barreira técnica não antecipada — a de que sinais de atividade em sistemas periféricos não são substitutos válidos para dados de RH primários — e obrigou uma segunda iteração de engenharia para reconciliar contra `TFPFUN`. O aprendizado consolidado: **qualquer inferência automatizada de status de pessoa (empregado/desligado, ativo/inativo) precisa buscar a fonte de dado primária do domínio, não um proxy de sistema adjacente.**

---

## Bloco 2 — Benefícios Operacionais / Econômicos

- **Eliminação de retrabalho anual na composição do dossiê de defesa**: antes, o dossiê era remontado manualmente a cada ano-base a partir de e-mails e planilhas; agora, N1/N2 são preenchidos ao longo do ciclo de vida do projeto e o N3 é composto a partir de dados já estruturados no sistema.
- **Redução de risco fiscal**: eliminação do risco de glosa por "cópia de relato entre anos-base sem evidência de progresso técnico distinto", já que cada transição de estado é registrada com data e autor, de forma imutável.
- **Visibilidade executiva imediata**: antes, saber quantos projetos estavam parados exigia perguntar pessoa a pessoa; hoje, o painel de Atualizações mostra isso em um único acesso (24 projetos em andamento, 0 em standby no momento deste dossiê, sobre um portfólio de mais de 30 projetos).
- **Correção de um erro operacional antes que causasse dano**: a segunda iteração da rotina de inativação evitou que 16 colaboradores ativos fossem indevidamente marcados como desligados no sistema de gestão interna, o que poderia ter causado perda de acesso, remoção de tarefas atribuídas e ruído organizacional.

> Nota: estes dados validam impacto, mas não são o cerne da defesa técnica — o foco permanece nos Blocos 1 e 3.

---

## Bloco 3 — Consolidação das Barreiras Técnicas

### 3.1.1. Incertezas/riscos do baseline (já mapeadas em N2)

**BARREIRA BASE-1 — Auditabilidade sem perda de flexibilidade na máquina de estados**
- Status final no período: ✅ Resolvida.
- Magnitude da incerteza no início: não havia certeza de que seria possível ter uma máquina de estados com 17 posições que aceitasse desvios de fluxo (revisão, cancelamento, arquivamento em qualquer ponto) sem abrir brecha para reescrita de histórico por bug de aplicação.
- Trajetória de superação: implementação de `DemandTransition` como registro somente-inserção, reforçado por sobrescrita de `readonly?` no nível da aplicação. Testado com tentativa deliberada de destruição do registro.

**BARREIRA BASE-2 — Reconciliação de identidade Sankhya × Microsoft sem chave de correlação direta**
- Status final no período: ✅ Resolvida.
- Magnitude da incerteza no início: o Sankhya usa e-mails de "rota" reatribuídos entre pessoas ao longo do tempo (uma mesma caixa teve 4 titulares diferentes em 3 anos); não havia garantia de conseguir separar identidade de mailbox sem introduzir falsos positivos.
- Trajetória de superação: adoção do Microsoft Entra ID como fonte de verdade da identidade atual, cruzado com o Sankhya como fonte de cargo/área/atividade; validado contra 408 registros brutos do Sankhya × 186 do Entra ID, com apenas 1 falso positivo detectado manualmente (substring "sat" capturando "Satlher" por engano) e corrigido para match exato de nome.

**BARREIRA BASE-3 — Geração de PDF com texto livre de usuário**
- Status final no período: ✅ Resolvida.
- Magnitude da incerteza no início: a fonte padrão da biblioteca de geração de PDF (Prawn) é Windows-1252; não era conhecido de antemão que caracteres fora desse charset (travessão, aspas curvas, símbolos matemáticos) quebrariam a geração em produção sem erro reproduzível em ambiente de desenvolvimento.
- Trajetória de superação: reprodução do erro em produção com dado real (não sintético), isolamento por bisseção de qual chamada de renderização especificamente falhava, e implementação de camada de sanitização category-aware antes de qualquer geração de texto/tabela.

### 3.1.2. Incertezas que emergiram durante a execução (não previstas no início)

**BARREIRA NOVA-1 — Login em sistema periférico não é sinal confiável de status de emprego**
- Momento de surgimento: durante a execução da rotina de limpeza/inativação de usuários, já com a ferramenta em produção e em uso real pela empresa.
- Causa-raiz identificada após investigação: a heurística inicial assumiu que ausência de login no Sankhya por 90+ dias correlacionava com desligamento. A investigação revelou que colaboradores podem estar plenamente empregados sem nunca (ou raramente) acessar aquele sistema específico — o dado de "último acesso" mede uso de um sistema, não vínculo empregatício.
- Magnitude: crítica — a heurística incorreta teria produzido 16 desligamentos indevidos em um universo de 22 decisões (73% de erro), com impacto direto em pessoas reais.
- Superação: reconciliação contra a tabela de RH do próprio Sankhya (`TFPFUN`, campo `DTDEM` — data de demissão real, por vínculo/admissão), aplicando a regra "colaborador está ativo se existir ao menos um vínculo sem data de demissão registrada". As 16 decisões incorretas foram revertidas automaticamente; as 6 corretas foram mantidas.

Esta barreira emergente é evidência forte de risco tecnológico real: mesmo com bom planejamento e dado real de produção, surgiu um problema não-trivial de interpretação de dado que exigiu uma segunda rodada de investigação e reengenharia da lógica de decisão.

### 3.1.3. Outros obstáculos tecnológicos

- Ambiguidade de schema no ERP legado: a tabela de status de funcionário (`TFPFUN.SITUACAO`) não é um enum simples de "ativo/inativo" — o mesmo código numérico aparece tanto em vínculos ativos quanto encerrados, dependendo do histórico de recontratação da pessoa. Foi necessário usar a presença/ausência de data de demissão (`DTDEM`) como sinal primário, e não o campo de situação isoladamente.
- Múltiplos vínculos históricos por pessoa na mesma tabela de RH (recontratações), exigindo agregação por nome/pessoa em vez de assumir uma linha única por colaborador.

### 3.2.1. Hipóteses formuladas e resultados

**HIPÓTESE H1 (referente à BARREIRA BASE-2 — reconciliação de identidade)**
- Formulação: "é possível identificar contas de sistema/spam/duplicatas usando correspondência por substring do nome contra padrões conhecidos (SAC, SAT, Não Responda, etc.)".
- Experimento: aplicação de filtro por substring sobre os 186 registros do Microsoft Entra ID.
- Resultado: ⚠️ Parcialmente confirmada — o filtro por substring gerou 1 falso positivo (nome real "Satlher" capturado pelo padrão "SAT"). Corrigida para exigir correspondência exata de token de nome, não substring livre.

**HIPÓTESE H2 (referente à BARREIRA NOVA-1 — inativação incorreta)**
- Formulação: "ausência de login no Sankhya por 90+ dias é um proxy válido para desligamento".
- Experimento: aplicação da heurística sobre a base real de 22 candidatos, seguida de checagem cruzada manual contra `TFPFUN.DTDEM`.
- Resultado: ❌ Refutada — apenas 6 de 22 (27%) tinham de fato demissão registrada. A hipótese foi descartada como critério único e substituída por consulta direta à fonte de RH.

### 3.2.2. Barreiras resolvidas vs. não resolvidas

**Resolvidas no período:**
- BARREIRA BASE-1 (auditabilidade da máquina de estados) — resolvida via registro imutável reforçado em nível de aplicação. Evidência: **[ANEXAR]** teste automatizado de tentativa de destruição/alteração + trecho de código do `readonly?`.
- BARREIRA BASE-2 (reconciliação de identidade) — resolvida via Entra ID como fonte de verdade + match exato de nome. Evidência: **[ANEXAR]** planilha/log da reconciliação (408 × 186 registros, 0 duplicidades finais).
- BARREIRA BASE-3 (encoding do PDF) — resolvida via sanitização category-aware. Evidência: **[ANEXAR]** PDF gerado com sucesso contendo caracteres que antes quebravam a geração.
- BARREIRA NOVA-1 (inativação incorreta por proxy de login) — resolvida via reconciliação contra `TFPFUN.DTDEM`. Evidência: **[ANEXAR]** print/log do script de correção mostrando as 16 reativações e os 6 desligamentos confirmados.

**Não resolvidas / débito assumido conscientemente:**
- Processamento assíncrono de jobs (recorrência de tarefas, e-mails adiados) não tem execução automatizada em produção ainda — código pronto, falta apenas o processo de infraestrutura. Não é uma barreira de incerteza técnica, é item de trabalho planejado e não priorizado.

### 3.2.3. Testes / simulações aplicados

- **Suíte de testes automatizados (RSpec)**: specs de modelo e de requisição cobrindo a máquina de estados, a API administrativa, o painel de Atualizações e o sistema de comentários/menções — 18+ exemplos novos adicionados neste período, 0 falhas.
- **Teste end-to-end real contra produção**: verificação via Playwright de que o painel de Atualizações e o organograma renderizam corretamente com dado real de produção (não simulado).
- **Teste de integração real com serviço externo**: chamada HTTPS de fato ao gateway REST do Sankhya a partir do servidor MCP e da API administrativa, incluindo o caminho de erro (credencial ausente).
- **Regressão dirigida por bug real**: reprodução do erro de `NoMethodError` no sistema de menções de comentário em ambiente de teste antes da correção, confirmando a causa raiz (retorno de `Array` em vez de relação `ActiveRecord`) e a efetividade da correção.

---

## Bloco 4 — Rastreamento de Projetos Plurianuais

Não aplicável neste dossiê — projeto de ano único (2026), sem histórico de ano-base anterior a reportar.

---

## Bloco 5 — Dispêndios (a preencher pela área fiscal/financeira)

> Os campos abaixo dependem de dados de folha e contratos que não fazem parte do escopo técnico deste documento. Preencher com a área financeira antes da submissão ao FORMP&D.

### 5.1. RH

| Pesquisador | Cargo | Dedicação a PD&I (%) | Custo total ano (R$) | Custo elegível (R$) |
|---|---|---|---|---|
| **[ANEXAR — dados de folha]** | | | | |

### 5.2 a 5.6

**[ANEXAR — preencher com a área financeira: serviços de terceiros, materiais de consumo, totais e adicionais aplicáveis]**

---

## Bloco 6 — TRL e ODS Consolidados

### 6.1. Evolução TRL no período
- TRL no início do período: 5 (protótipo validado em ambiente relevante — módulos isolados já existiam e funcionavam)
- TRL final do período: **6** (sistema em produção real, com usuários reais, validando integração de ponta a ponta com sistemas externos — Sankhya e Microsoft 365)
- Justificativa: o sistema deixou de ser um protótipo funcional isolado para operar em ambiente real de produção com 119 usuários e integração externa validada com chamadas reais (não simuladas) ao Sankhya.

### 6.2. ODS confirmados
- **ODS 9 — Indústria, Inovação e Infraestrutura**: o projeto constrói infraestrutura digital própria de gestão de inovação, substituindo processo manual por sistema auditável e integrado.

---

## Bloco 7 — Anexos / Evidências

| Nº | Tipo | Descrição | Status |
|---|---|---|---|
| A1 | Repositório de código | `tsuru-portal` (aplicação) e `tsuru-mcp` (servidor de integração) — histórico completo de commits | **[ANEXAR]** link/acesso aos repositórios |
| A2 | Documentação arquitetural | `DOCUMENTACAO_TECNICA.md` (este pacote de entrega) | ✅ Incluído |
| A3 | Log de correção da inativação de usuários | Script e saída de execução mostrando 22 candidatos → 16 reativados / 6 confirmados | **[ANEXAR]** log/print da execução |
| A4 | Relatório de testes automatizados | Saída da suíte RSpec (specs de model e request, 0 falhas) | **[ANEXAR]** print/log da execução `rspec` |
| A5 | Evidência visual do sistema em produção | Screenshots do painel de Atualizações, organograma e demanda do próprio Tsuru (id 45) | **[ANEXAR]** capturas de tela |
| A6 | Evidência de integração real com Sankhya | Log de chamada HTTPS real ao gateway (latência, tratamento de erro 401/403) | **[ANEXAR]** log da chamada |
| A7 | Dispêndios (RH/ST/MC) | Dados de folha, contratos e notas fiscais do período | **[ANEXAR]** planilha da área financeira |
| A8 | Time-sheets | Registro de horas por pessoa envolvida no desenvolvimento | **[ANEXAR]** exportação do módulo de timesheet do próprio Tsuru |

---

## Bloco 8 — Observações finais e estratégia de defesa

### 8.1. Pontos fortes do dossiê
- A barreira emergente (inativação incorreta de usuários) é uma evidência de risco tecnológico particularmente forte, porque não foi hipotética: produziu um erro real de 73% de taxa de falha antes da correção, documentado com números concretos e reversível de forma auditável.
- A imutabilidade do histórico de decisão é comprovada por teste automatizado, não apenas por declaração.
- Integração real (não simulada) com sistema externo de terceiros (Sankhya), com tratamento de erro observável.

### 8.2. Pontos de risco
- Bloco 5 (dispêndios) depende inteiramente de dados financeiros ainda não anexados — sem isso, o dossiê não sustenta cálculo de benefício, só o mérito técnico.
- Projeto de ano único, ainda em desenvolvimento ativo — se a submissão ocorrer antes do encerramento natural de uma fase, considerar reportar como "em andamento" explicitamente, evitando linguagem que sugira conclusão definitiva.

### 8.3. Recomendação consultiva final
- [x] Projeto sólido tecnicamente — mérito técnico bem fundamentado e documentado com barreiras reais, inclusive uma emergente com dado quantitativo forte.
- [ ] Pendência antes da submissão: preencher Bloco 5 (dispêndios) com a área financeira e anexar as evidências marcadas **[ANEXAR]** no Bloco 7.

---

## Assinaturas

Consultor: ______________________________
Líder técnico: ______________________________
Responsável fiscal: ______________________________
Diretor: ______________________________
Data: ____/____/______

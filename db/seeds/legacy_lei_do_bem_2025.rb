# frozen_string_literal: true

# ============================================================
# IMPORT — Projetos legados Lei do Bem ciclo 2025-2026
# Fonte autoritativa: "PLANILHA NOVA MCTI CONTROLE PROJETOS 2025-2026 (10).xlsx"
#                    + Declaração de elegibilidade FI Group
# ============================================================
# Idempotente: usa find_or_initialize_by(title:) — pode rodar várias vezes.
# Marca cada Demand com n2_assessment["fonte"] = "import_lei_do_bem_2025"
# e n2_assessment["codigo_legado"] = "INOVA BEL-XXX" para rastreabilidade.
#
# Executar:
#   bundle exec rails runner db/seeds/legacy_lei_do_bem_2025.rb
# Ou com dry-run:
#   DRY_RUN=true bundle exec rails runner db/seeds/legacy_lei_do_bem_2025.rb
# ============================================================

ANO_BASE     = 2025
AUTOR_EMAIL  = "admin@tsuru.local"
FONTE_IMPORT = "import_lei_do_bem_2025"
DRY_RUN      = ENV["DRY_RUN"] == "true"

# Estados conforme análise REAL da coluna "Análise de Elegibilidade (Exclusivo FI)"
# e "Declaração de elegibilidade FI Group" da planilha MCTI.
#  - "Elegível" explícito da FI Group → :elegivel
#  - "A definir" / sem declaração formal → :n2_em_andamento (avaliação ainda em curso)
ESTADO_POR_CODIGO = {
  "INOVA BEL-001"     => "elegivel",         # FI: Elegível
  "INOVA BEL 001/2"   => "elegivel",         # FI: Elegível ("Após análise técnica...")
  "INOVA BEL-003"     => "elegivel",         # FI: Elegível
  "INOVA BEL-004"     => "elegivel",         # FI: Elegível
  "INOVA BEL-005"     => "elegivel",         # Considerações: "enquadrado como P&D aplicado, elegível"
  "INOVA BEL-005.1"   => "n2_em_andamento",  # FI: A definir / A definir
  "INOVA BEL-006"     => "elegivel",         # FI: continuação consolidada (ano anterior elegível)
  "INOVA BEL-007"     => "elegivel",         # FI: Elegível
  "INOVA BEL-008"     => "elegivel",         # FI: Elegível
  "INOVA BEL-009"     => "elegivel",         # FI: Elegível
  "INOVA BEL-010"     => "elegivel",         # FI: Elegível
  "INOVA BEL-012"     => "elegivel",         # FI: Elegível
  "INOVA BEL-013"     => "n2_em_andamento",  # FI: sem decl. formal (MVP validado)
  "INOVA BEL-014"     => "n2_em_andamento",  # FI: "Não informado no relatório"
  "INOVA BEL-015"     => "elegivel",         # FI: Elegível
  "INOVA BEL-016"     => "n2_em_andamento",  # FI: A definir / A definir
  "INOVA BEL-017"     => "elegivel"          # Considerações: "projeto ativo, elegível"
}.freeze

# Helper: triagem N1 padrão para projetos JÁ aprovados pela FI Group
# (todos os flags = false = nenhuma das exclusões; passou N1).
N1_OK = {
  "rotina_operacional"     => false,
  "adequacao_normativa"    => false,
  "cots_sem_customizacao"  => false,
  "trl_fora_janela"        => false,
  "escopo_nao_tecnologico" => false
}.freeze

# ===========================================================
# 17 projetos legados (planilha MCTI sheet "Projetos")
# ===========================================================
projetos = [
  {
    codigo: "INOVA BEL-001",
    title: "INOVA BEL 001 — Transformação Digital e Otimização de Vendas",
    area: "TI / Sistemas", urgencia: "Atrapalha o dia a dia",
    trl_inicial: 4, trl_final: 8, ods: [8, 9, 12],
    natureza: "desenvolvimento_experimental",
    description: "Integrar e automatizar fluxos entre ERP Sankhya, RDVi, SouChat, ONSIG e WMW, com replicação de dados em tempo real e uso de IA. Projeto matriz da transformação digital da Bel Lube — referência para o portfólio inteiro de PD&I 2025-2026.",
    solucao_proposta: "Antes: integrações pontuais, dados desincronizados entre ERP/RDV/WMW, sem MDM, baixa observabilidade. Depois: arquitetura API-first com contratos versionados, mensageria, MDM/DQ, replicação em tempo real e observabilidade fim a fim, conforme LGPD.",
    barreira_tecnica: "Integração entre múltiplos sistemas legados (Sankhya/Oracle, IBM System/z + WebSphere, RDV, WMW), latência aceitável para replicação em tempo real, MDM e Data Quality sobre bases heterogêneas, governança LGPD.",
    tecnologias: "MySQL, Oracle; JavaScript, Java; ERP Sankhya; RDVi; SouChat; ONSIG; WMW; IBM System/z; WebSphere; IDEAL; API-first; mensageria; observabilidade",
    parecer: "Elegível conforme análise FI Group. Projeto matriz da transformação digital; comprovado salto tecnológico via integração API-first sobre stack heterogênea com replicação em tempo real, MDM e LGPD.",
    parcerias: ["Nova Gestão Tecnologia e Serviços LTDA", "WMW Systems LTDA", "GERTH Consultoria e Promoções de Vendas LTDA", "Cloud Labs", "ON SIG Rastreamento", "Sankhya Jiva Tecnologia e Inovação LTDA", "TD Sinnex Brasil LTDA"]
  },
  {
    codigo: "INOVA BEL 001/2",
    title: "Subprojeto INOVA BEL001 — Roteirização Regional+",
    area: "Logística / Suprimentos", urgencia: "Atrapalha o dia a dia",
    trl_inicial: 4, trl_final: 7, ods: [8, 9, 11],
    natureza: "desenvolvimento_experimental",
    description: "Implementar roteirização inteligente com classificação A/B/C de clientes, integração RDV ↔ Sankhya ↔ Onsig em tempo real, leads para guiar visitas e ajustes contínuos baseados em performance. Cobertura Norte de Minas, Sul de Minas, Grande BH, Zona da Mata e Região de Consumo.",
    solucao_proposta: "Antes: rotas montadas manualmente, base de clientes desatualizada, clientes fora de rota, baixa conversão. Depois: roteirização A/B/C, dados em tempo real, integração sistêmica RDV-Sankhya-Onsig, ajustes contínuos por KPI.",
    barreira_tecnica: "Integração entre múltiplos sistemas (RDV/Sankhya/Onsig), padronização e limpeza da base de dados, adaptação dos algoritmos de roteirização à realidade regional, validação da eficácia em campo.",
    tecnologias: "Python; SQL; RDV; ERP Sankhya; Onsig Rastreamento; SCRUM; design pattern MVC; APIs de integração",
    parecer: "Elegível. Subprojeto com pesquisa aplicada e desenvolvimento experimental em algoritmos de priorização e integração de dados em tempo real.",
    parcerias: ["Nova Gestão Tecnologia e Serviços LTDA", "WMW Systems LTDA", "ON SIG Rastreamento", "Sankhya Jiva Tecnologia e Inovação LTDA", "TD Sinnex Brasil LTDA", "GERTH Consultoria e Promoções de Vendas LTDA"]
  },
  {
    codigo: "INOVA BEL-003",
    title: "Trade — Motor Creditício Integrado à Visita",
    area: "Comercial", urgencia: "Está travando o atendimento ou o cliente",
    trl_inicial: 3, trl_final: 6, ods: [8, 9],
    natureza: "desenvolvimento_experimental",
    description: "Migrar de fluxo reativo (crédito pós-pedido) para orientado a eventos (visita → decisão → pedido). Endpoint único de crédito; integração RDV ↔ Sankhya ↔ Trade ↔ Crédito. Base Única de Eventos para 10.000+ clientes; pilotos em BH e SP.",
    solucao_proposta: "Antes: processos manuais e fragmentados, crédito reativo, RDV não integrado ao Trade, vendedor externo sem monetização da visita, APIs incompletas. Depois: motor creditício orientado a eventos com endpoint único de crédito, telemetria fim a fim e redução do tempo de liberação.",
    barreira_tecnica: "Ausência de motor creditício orientado a eventos e endpoint unificado; necessidade de Base Única de Eventos padronizada; latência de liberação de crédito; risco de codificar regras sem owners; testes de carga e segurança em escala (10k+ clientes).",
    tecnologias: "Oracle; ERP Sankhya; APIs orientadas a serviços (OpenAPI); integração contínua; design pattern SOA; Plataforma Trade Master + Sankhya",
    parecer: "Elegível. Desenvolvimento de motor creditício event-driven inédito na operação, com risco tecnológico real em integração, contratos de API e validação em pilotos.",
    parcerias: ["Trends Tecnologia e Inovação", "Trade Master Concessora de Crédito", "Sankhya Jiva Tecnologia e Inovação LTDA"]
  },
  {
    codigo: "INOVA BEL-004",
    title: "Plataforma logística Megleo — gestão de custos de transporte com IA",
    area: "Logística / Suprimentos", urgencia: "Atrapalha o dia a dia",
    trl_inicial: 3, trl_final: 7, ods: [8, 9, 12, 13],
    natureza: "desenvolvimento_experimental",
    description: "Reduzir custo logístico e tempo de atendimento com cotação em tempo real, conferência automática de faturas (Quick Payment CT-e), rastreabilidade fim a fim e SAC IA, integrando Megleo ↔ Sankhya ↔ transportadoras.",
    solucao_proposta: "Antes: processos pouco controlados, sem cotação integrada, rotas críticas (Sul de Minas) com até 15 dias de prazo, SAC reativo, penalizações ad hoc. Depois: cotação automática em tempo real, Quick Payment CT-e, SAC com IA via WhatsApp Business (Meta), BI self-service Quick Analysis e App do Motorista.",
    barreira_tecnica: "Integração nativa Sankhya × Megleo e retorno de arquivos das transportadoras; dependência de dados operacionais reais para ajuste fino; cotação centralizada perdendo timing da visita; SAC IA com BOT Meta; penalização sistêmica de compliance.",
    tecnologias: "Oracle; ERP Sankhya; Megleo; APIs REST (SOA); integração contínua; Design Pattern: comunicação orientada a serviços; SAC IA com BOT oficial Meta (WhatsApp), IMBOX, Kanban",
    parecer: "Elegível. Salto tecnológico via plataforma logística IA-driven, com risco real em integração nativa Sankhya×Megleo e SAC IA produtivo.",
    parcerias: ["Megleo Inovação e Logística", "Nova Gestão Tecnologia e Serviços LTDA", "ASSÉ Projetos"]
  },
  {
    codigo: "INOVA BEL-005",
    title: "Mais Pessoas (RH) — Transformação Digital",
    area: "RH", urgencia: "Atrapalha o dia a dia",
    trl_inicial: 3, trl_final: 7, ods: [3, 8, 10],
    natureza: "desenvolvimento_experimental",
    description: "Digitalizar e integrar todo o ciclo de RH (recrutamento, seleção, integração) automatizando ATS ↔ ERP ↔ SST (Gupy ↔ Sankhya ↔ SOC), com rastreabilidade, dashboards e conformidade NR01/ISO 45003.",
    solucao_proposta: "Antes: processos manuais, sem integração ATS↔ERP↔SST, baixa rastreabilidade, sem gestão visual. Depois: arquitetura integrada com APIs/webhooks, SSO/LDAP, auditoria documental, dashboards e gestão visual replicável ao CRM.",
    barreira_tecnica: "Compatibilidade/versionamento de APIs entre Gupy, Sankhya e SOC; qualidade e mapeamento de dados; governança LGPD; padronização da gestão visual (NR17/NR26); registro PGR (NR01); adoção dos colaboradores.",
    tecnologias: "Gupy ATS; Sankhya CRM/ERP; SOC SST; APIs REST/JSON; Webhooks; Scrum/Kanban; Event-driven; Adapter Pattern; HR analytics; LGPD; ISO 45003; NR01 (GRO/PGR)",
    parecer: "Elegível. Integração inédita ATS↔ERP↔SST com automação de fluxos de RH e compliance NR01/ISO 45003.",
    parcerias: ["Gupy", "Nova Gestão Tecnologia e Serviços LTDA", "Law Trends Consultoria", "Sankhya Jiva Tecnologia e Inovação LTDA", "SOC"]
  },
  {
    codigo: "INOVA BEL-005.1",
    title: "Subprojeto ONSIG + RH + Pessoas — Jornada, Ponto por Exceção e Compliance Trabalhista",
    area: "RH", urgencia: "Posso esperar — é uma melhoria",
    trl_inicial: 2, trl_final: 5, ods: [3, 8],
    natureza: "desenvolvimento_experimental",
    description: "Implantar modelo automatizado de controle de jornada baseado em dados ONSIG com foco em compliance e rastreabilidade, vinculado ao projeto matriz INOVA BEL 001.",
    solucao_proposta: "Antes: controle manual de jornada, sem rastreabilidade confiável, risco de passivo trabalhista. Depois: jornada automatizada via ONSIG com evidência técnica, ponto por exceção e auditoria trabalhista.",
    barreira_tecnica: "Integração ONSIG com regras de ACT/CLT; tratamento de exceções; modelagem de jornada por área operacional; padronização de relatórios.",
    tecnologias: "ONSIG; planilhas de validação; automação de regras de jornada; ETL para auditoria",
    parecer: "Em definição final pela FI Group. Projeto de compliance com base técnica, integrado ao matriz INOVA BEL 001.",
    parcerias: ["ON SIG Rastreamento"]
  },
  {
    codigo: "INOVA BEL-006",
    title: "Ivalor B2B — E-commerce",
    area: "Comercial", urgencia: "Atrapalha o dia a dia",
    trl_inicial: 4, trl_final: 8, ods: [8, 9, 12],
    natureza: "desenvolvimento_experimental",
    description: "Portal digital B2B integrado ao ERP/CRM Sankhya e à plataforma Fastchannel, permitindo a 15.000 clientes corporativos acesso autônomo a produtos, preços, estoque e pedidos em tempo real.",
    solucao_proposta: "Antes: atendimento manual, dependência de equipes internas, sistemas não integrados, alto custo operacional. Depois: portal B2B integrado, atualização automática de preços/estoque, pedidos online com status em tempo real, autonomia do cliente corporativo escalável a 15k.",
    barreira_tecnica: "Integração em tempo real entre sistemas legados e novas plataformas; sincronização dinâmica de preço e estoque; gestão de alto volume de dados e pedidos simultâneos; performance e confiabilidade; particularidades do atendimento B2B.",
    tecnologias: "Java; Python; SQL; ERP/CRM Sankhya; Fastchannel; APIs REST; webhooks; integração contínua; UX B2B",
    parecer: "Elegível. Portal B2B com integração ERP/CRM em tempo real e sincronização automática de preço/estoque para escala de 15k clientes.",
    parcerias: ["Fastchannel", "GERTH Consultoria e Promoções de Vendas LTDA", "Hora Um Marketing", "Nova Gestão Tecnologia e Serviços LTDA", "FIEMG/IEL", "Time Iconic"]
  },
  {
    codigo: "INOVA BEL-007",
    title: "Motor Oil — Automação Inteligente de Marketing de Incentivo B2B e B2C",
    area: "Comercial", urgencia: "Posso esperar — é uma melhoria",
    trl_inicial: 3, trl_final: 7, ods: [8, 9, 12],
    natureza: "desenvolvimento_experimental",
    description: "Ecossistema digital inteligente para automatizar e personalizar campanhas de incentivo, integrando plataformas e APIs com IA aplicada ao neuromarketing. Piloto na Sion Lubrificantes.",
    solucao_proposta: "Antes: campanhas pontuais, pouca automação, baixo uso de dados. Depois: solução integrada com IA, personalização por perfil comportamental, automação de interações, integração B2B/B2C e monitoramento contínuo por KPIs.",
    barreira_tecnica: "Integração eficiente entre múltiplas plataformas; adoção de IA pelos usuários; segurança e privacidade (LGPD) em ambientes B2B/B2C; escalabilidade das campanhas automatizadas.",
    tecnologias: "Python; JavaScript; MySQL; MongoDB; Sankhya; Apura Inova; PIX Pontos; TEENS; Scrum; APIs RESTful B2B/B2C; design patterns orientação a serviços",
    parecer: "Elegível. Implementação de motor de incentivo com IA e integrações B2B/B2C inéditas; risco tecnológico em integração multi-plataforma e conformidade LGPD.",
    parcerias: ["Apura Inova", "PIX Pontos", "TEENS", "Sankhya Jiva Tecnologia e Inovação LTDA", "Mercado Livre", "Gupy", "Sion Lubrificantes"]
  },
  {
    codigo: "INOVA BEL-008",
    title: "Movidesk — SAC Integrado, Rastreabilidade e Compliance Operacional",
    area: "Atendimento", urgencia: "Atrapalha o dia a dia",
    trl_inicial: 4, trl_final: 7, ods: [8, 9],
    natureza: "desenvolvimento_experimental",
    description: "Service Desk Movidesk para registrar, organizar, monitorar e resolver solicitações internas e externas com SLAs, histórico auditável e indicadores de desempenho, abrangendo Logística, RH, Compras, Comercial, Financeiro e Administrativo.",
    solucao_proposta: "Antes: comunicação fragmentada, baixa rastreabilidade de atendimentos, falta de padronização. Depois: SAC centralizado com SLAs, ITSM padronizado, integração conceitual com ERP/CRM, indicadores de governança.",
    barreira_tecnica: "Padronização e configuração correta de fluxos/SLAs; adoção cultural; integração conceitual com ERP sem API direta; mapeamento de processos heterogêneos entre áreas.",
    tecnologias: "Movidesk; parametrização de fluxos e SLAs; metodologias ágeis; ITSM",
    parecer: "Elegível. Centralização com governança e SLAs e adoção de ITSM adaptado; risco moderado em padronização de fluxos e adoção cultural.",
    parcerias: ["Movidesk", "Nova Gestão Tecnologia e Serviços LTDA", "Sankhya Jiva Tecnologia e Inovação LTDA"]
  },
  {
    codigo: "INOVA BEL-009",
    title: "NEPPO — Atendimento Integrado e Padronizado com Otimização de Processos",
    area: "Atendimento", urgencia: "Atrapalha o dia a dia",
    trl_inicial: 3, trl_final: 6, ods: [8, 9],
    natureza: "desenvolvimento_experimental",
    description: "Plataforma omnichannel NEPPO integrada ao ERP/CRM Sankhya via API e ao WhatsApp Business API (META), com automação de fluxos e segurança da informação.",
    solucao_proposta: "Antes: plataforma anterior instável, sem rastreabilidade, sem integração com ERP. Depois: omnichannel integrado via API oficial META + ERP Sankhya, fluxos padronizados, melhor direcionamento e maior controle.",
    barreira_tecnica: "Adaptação dos colaboradores; mudança para lógica de atendimento ativo; dependência do retorno do cliente; correta configuração da API META; alinhamento de fluxos à rotina operacional.",
    tecnologias: "Plataforma NEPPO; ERP/CRM Sankhya via API; WhatsApp Business API (META); metodologias ágeis",
    parecer: "Elegível. Integração omnichannel com API oficial META e ERP; risco tecnológico real em configuração correta e adesão.",
    parcerias: ["NEPPO", "Nova Gestão Tecnologia e Serviços LTDA", "Sankhya Jiva Tecnologia e Inovação LTDA", "META"]
  },
  {
    codigo: "INOVA BEL-010",
    title: "Boleto PIX Bell — Integração Financeira, Automação e Governança de Recebíveis",
    area: "Financeiro", urgencia: "Atrapalha o dia a dia",
    trl_inicial: 4, trl_final: 8, ods: [8, 9],
    natureza: "desenvolvimento_experimental",
    description: "Modernizar cobrança e recebimento via Boleto PIX integrado, com baixa financeira automática, emissão imediata de Nota Fiscal e liberação logística sincronizada; segurança e compliance auditáveis.",
    solucao_proposta: "Antes: pagamentos com conferências manuais, liberações posteriores à compensação, risco de inconsistências entre banco/financeiro/logística. Depois: recebimento via Boleto PIX integrado, baixa financeira automática, NF imediata e liberação logística sincronizada.",
    barreira_tecnica: "Integração financeira segura com PIX; conciliação bancária automática; segurança de dados financeiros sensíveis; conformidade fiscal e auditoria.",
    tecnologias: "Java; ERP Sankhya; APIs bancárias PIX; integração com fiscal e logística; segurança de dados financeiros",
    parecer: "Elegível. Integração financeira automatizada com ERP e PIX; risco tecnológico em integração segura e validação de dados sensíveis.",
    parcerias: ["Sankhya Jiva Tecnologia e Inovação LTDA", "Nova Gestão Tecnologia e Serviços LTDA", "FC Consultoria", "MMA Lopes Consultoria"]
  },
  {
    codigo: "INOVA BEL-012",
    title: "Retira Just-in-Time + Granel + Monitoramento IoT",
    area: "Logística / Suprimentos", urgencia: "Atrapalha o dia a dia",
    trl_inicial: 3, trl_final: 7, ods: [8, 9, 12, 13],
    natureza: "desenvolvimento_experimental",
    description: "JIT formalizado (≤5 min de atendimento), Expresso Bel (raio 50 km), ONSIG com rotas e SLA, etiquetagem integrada a Sankhya/Megleo, telemetria/auditoria por logs, padronização de granel com sensores IoT.",
    solucao_proposta: "Antes: filas e espera prolongada, rotas manuais, etiquetagem pouco integrada, retirada/enchimento sem padrão. Depois: JIT ≤5 min, Expresso Bel raio 50 km, ONSIG com rotas/SLA, etiquetagem integrada Sankhya/Megleo, IoT no granel.",
    barreira_tecnica: "Latência e comunicação com servidores; integração entre sistemas distintos; qualidade de dados (estoque/etiquetas); SLA do Expresso Bel sob picos; calibração de sensores ultrassônicos em ambiente industrial; padronização IoT↔ERP.",
    tecnologias: "Sankhya; ONSIG; Megleo; IoT (sensores ultrassônicos Wi-Fi 2.4 GHz IP65/67); APIs REST/JSON; MQTT; Webhooks; Oracle/ERP; Scrum/Kanban; SOA / Event-driven",
    parecer: "Elegível. Integração sistêmica de logística com IoT industrial; risco tecnológico em calibração, latência e SLAs.",
    parcerias: ["ASSÉ Projetos", "Trends Tecnologia e Inovação", "Megleo Inovação e Logística", "Sankhya Jiva Tecnologia e Inovação LTDA"]
  },
  {
    codigo: "INOVA BEL-013",
    title: "MITRA — Plataforma No-Code para Governança de Dados, Dashboards Estratégicos e Otimização da Gestão Comercial",
    area: "TI / Sistemas", urgencia: "Posso esperar — é uma melhoria",
    trl_inicial: 3, trl_final: 6, ods: [8, 9, 12],
    natureza: "desenvolvimento_experimental",
    description: "Plataforma MITRA integrada ao ERP Sankhya para centralizar dados, eliminar planilhas manuais e disponibilizar dashboards estratégicos com governança de dados, LGPD e No-Code.",
    solucao_proposta: "Antes: controles manuais, uso intensivo de planilhas, baixa padronização, falta de visão consolidada. Depois: dados centralizados, integração ERP, dashboards dinâmicos, regras automatizadas, governança e maturidade digital.",
    barreira_tecnica: "Padronização de dados entre fontes distintas; integração segura ERP-MITRA; controle hierárquico de acesso; LGPD; aderência da plataforma No-Code ao processo comercial real.",
    tecnologias: "Plataforma MITRA; ERP Sankhya; dashboards HTML dinâmicos; metodologias ágeis; governança de dados; No-Code",
    parecer: "Elegível. Plataforma de governança de dados com integração ERP e MVP validado.",
    parcerias: ["MITRA", "Sankhya Jiva Tecnologia e Inovação LTDA"]
  },
  {
    codigo: "INOVA BEL-014",
    title: "Simulador de Preço Bel Lube v3",
    area: "Comercial", urgencia: "Atrapalha o dia a dia",
    trl_inicial: 3, trl_final: 6, ods: [8, 9],
    natureza: "desenvolvimento_experimental",
    description: "Aplicação corporativa para apoiar a área comercial em simulações de venda com velocidade, padronização e confiabilidade: consulta de clientes/produtos, condições financeiras, montagem de pedidos simulados, indicadores econômicos, persistência e rastreabilidade por perfil de acesso.",
    solucao_proposta: "Antes: simulações dependentes de processos manuais com divergências de cálculo e baixa qualidade de informação. Depois: aplicação web completa com autenticação JWT, perfis de acesso, motor de simulação multi-item, persistência e histórico, integração SQL Server (Sankhya) ↔ PostgreSQL.",
    barreira_tecnica: "Integração entre SQL Server (Sankhya) e PostgreSQL com sincronismo; autenticação/sessão JWT com segregação por perfis; motor funcional de simulação com múltiplos itens; segurança HTTP, CORS, rate limit, logs estruturados; preparação operacional para sustentação (PM2, systemd, scripts).",
    tecnologias: "Node.js + Express (backend); HTML/CSS/JavaScript (frontend); PostgreSQL; SQL Server (Sankhya); JWT; PM2; systemd; logs estruturados; healthcheck; CORS; rate limiting",
    parecer: "Elegível. Aplicação corporativa com motor de simulação, integração heterogênea de dados e sustentação operacional consolidada. Esforço técnico estimado em 160 horas.",
    parcerias: ["Nova Gestão Tecnologia e Serviços LTDA", "GERTH Consultoria e Promoções de Vendas LTDA", "MMA Lopes Consultoria"]
  },
  {
    codigo: "INOVA BEL-015",
    title: "InovaBel PromptAI — Automação Inteligente com IA",
    area: "TI / Sistemas", urgencia: "Posso esperar — é uma melhoria",
    trl_inicial: 3, trl_final: 6, ods: [8, 9],
    natureza: "desenvolvimento_experimental",
    description: "Automatizar e otimizar processos corporativos críticos com aplicação de IA via prompts personalizados integrados aos sistemas existentes (Sankhya, MITRA, OpenAI), com governança e segurança.",
    solucao_proposta: "Antes: processos manuais, baixa integração. Depois: automação inteligente com IA, integração plena, processos padronizados e rastreáveis.",
    barreira_tecnica: "Integração da IA com múltiplos sistemas; precisão e governança dos prompts; segurança e governança de dados; controle de versão de modelos.",
    tecnologias: "Python; JavaScript; PostgreSQL; OpenAI; Scrum; padrões MVC e Microsserviços",
    parecer: "Elegível. P&D aplicado com evolução incremental e riscos tecnológicos em integração IA × sistemas legados.",
    parcerias: ["ASSÉ Projetos", "Law Trends Consultoria", "GERTH Consultoria e Promoções de Vendas LTDA", "FC Consultoria", "OpenAI"]
  },
  {
    codigo: "INOVA BEL-016",
    title: "Solução Integrada de Governança Contábil, Fiscal e Operacional (Reforma Tributária CBS/IBS)",
    area: "Financeiro", urgencia: "Está travando o atendimento ou o cliente",
    trl_inicial: 2, trl_final: 5, ods: [8, 9, 16],
    natureza: "desenvolvimento_experimental",
    description: "Solução tecnológica com arquitetura de dados estruturada, modelagem de regras, validação automatizada e rastreabilidade transacional (TRN) para integração e governança contábil/fiscal/operacional, com adaptação dinâmica à Reforma Tributária (CBS, IBS, split payment).",
    solucao_proposta: "Antes: ambiente fragmentado, controles paralelos, baixa integração, alto risco fiscal. Depois: ambiente integrado com arquitetura de dados, validação automatizada, rastreabilidade transacional (TRN) e adaptação dinâmica às novas regras tributárias.",
    barreira_tecnica: "Integração entre sistemas distintos com diferentes padrões; ausência de modelo de mercado para TRN aplicada à Reforma Tributária; complexidade normativa (CBS/IBS/split payment); padronização cadastral e qualidade de dados; rateio de custos e validação automatizada.",
    tecnologias: "ERP Sankhya; MITRA; OpenAI; APIs REST; ETL; banco de dados estruturado; modelagem relacional; integração sistêmica; governança de dados",
    parecer: "Em definição final pela FI Group. Projeto estruturante para adequação à Reforma Tributária; risco tecnológico real em TRN, integração heterogênea e simulação CBS/IBS.",
    parcerias: ["Sankhya Jiva Tecnologia e Inovação LTDA", "MITRA", "OpenAI"]
  },
  {
    codigo: "INOVA BEL-017",
    title: "Sistema Integrado de Segurança Inteligente — Modelo Regional + Dash Unificado",
    area: "Operacional", urgencia: "Posso esperar — é uma melhoria",
    trl_inicial: 3, trl_final: 6, ods: [9, 11, 16],
    natureza: "desenvolvimento_experimental",
    description: "Prevenir incidentes e elevar a proteção corporativa com sistema integrado de segurança inteligente, monitoramento regional, reconhecimento facial e leitura de placas, dash consolidado e resposta rápida.",
    solucao_proposta: "Antes: segurança sem visão consolidada, sem integração entre tecnologias e bases regionais. Depois: sistema integrado regional com IA (Wisenet, Geovision, LTS) + dash MITRA + logs Sankhya, com governança e LGPD.",
    barreira_tecnica: "Integração de múltiplas tecnologias (câmeras IA, reconhecimento facial, leitura de placas); adequação a diferentes layouts regionais; precisão dos algoritmos; estabilidade do sistema sob operação 24x7; LGPD em dados sensíveis.",
    tecnologias: "Câmeras IA Wisenet; reconhecimento facial Geovision; leitura de placas LTS; integração com Sankhya; dash MITRA; LGPD",
    parecer: "Elegível. Sistema integrado de segurança inteligente com IA aplicada e governança consolidada; risco tecnológico real em integração e precisão.",
    parcerias: ["JGF Monitoramento", "JCF Monitoramento", "TGM", "MITRA", "Sankhya Jiva Tecnologia e Inovação LTDA"]
  }
]

# ============================================================
# Execução
# ============================================================
puts "=" * 70
puts "Import legado Lei do Bem #{ANO_BASE} — #{DRY_RUN ? 'DRY RUN' : 'EXECUÇÃO REAL'}"
puts "=" * 70

autor = User.find_by!(email: AUTOR_EMAIL)
puts "Autor: #{autor.email} (#{autor.role})"
puts "Projetos a importar: #{projetos.size}"
puts

ActiveRecord::Base.transaction do
  projetos.each_with_index do |p, i|
    print "[#{(i+1).to_s.rjust(2)}/#{projetos.size}] #{p[:codigo].ljust(18)} #{p[:title][0..60]}... "

    demand = Demand.find_or_initialize_by(title: p[:title])
    new_record = demand.new_record?

    demand.user             = autor
    demand.description      = p[:description]
    demand.solucao_proposta = p[:solucao_proposta]
    demand.area_impactada   = p[:area]
    demand.urgencia         = p[:urgencia]
    demand.trl              = p[:trl_final]
    demand.ods_goals        = p[:ods]
    demand.parecer_tecnico  = p[:parecer]
    demand.n1_flags         = N1_OK.dup
    demand.n2_assessment    = {
      "fonte"             => FONTE_IMPORT,
      "codigo_legado"     => p[:codigo],
      "barreira_tecnica" => p[:barreira_tecnica],
      "tecnologias"       => p[:tecnologias],
      "natureza"          => p[:natureza],
      "trl_inicial"       => p[:trl_inicial],
      "trl_final"         => p[:trl_final],
      "parecer_fi_group"  => p[:parecer],
      "importado_em"      => Time.current.iso8601
    }
    estado_real = ESTADO_POR_CODIGO[p[:codigo]] || "n2_em_andamento"
    demand.aasm_state = estado_real
    demand.n2_assessment["estado_origem_fi"] = estado_real
    unless demand.valid?
      puts "\n  !! Demand inválida (#{p[:codigo]}):"
      demand.errors.each { |e| puts "     - #{e.attribute}: #{e.type} | #{e.message.to_s[0..200]}" }
      raise "validation error em Demand #{p[:codigo]}"
    end
    demand.save!

    # LeiDoBemRecord (1:1 com demand)
    ldb = LeiDoBemRecord.find_or_initialize_by(demand_id: demand.id)
    ldb.ano_base            = ANO_BASE
    ldb.natureza_projeto    = p[:natureza]
    ldb.regime_tributacao   = "lucro_real_anual"
    ldb.trl_inicial         = p[:trl_inicial]
    ldb.trl_final           = p[:trl_final]
    ldb.ods_projeto         = p[:ods].map(&:to_s) # text[] coluna; validação faz .to_i (1..17)
    ldb.parecer_consolidado = p[:parecer]
    ldb.base_zero_pesquisadores = false
    ldb.tem_patente         = false
    ldb.total_dispendios    = 0.0
    unless ldb.valid?
      puts "\n  !! LeiDoBemRecord inválido (#{p[:codigo]}):"
      ldb.errors.each { |e| puts "     - #{e.attribute}: #{e.type} | #{e.message.to_s[0..200]}" }
      raise "validation error em LeiDoBemRecord #{p[:codigo]}"
    end
    ldb.save!

    # Parcerias / fornecedores
    (p[:parcerias] || []).each do |nome|
      Partnership.find_or_create_by!(lei_do_bem_record_id: ldb.id, ict_nome: nome) do |pa|
        pa.tipo               = "empresa_pesquisa"
        pa.data_inicio        = Date.new(ANO_BASE, 1, 1)
        pa.data_fim           = Date.new(ANO_BASE, 12, 31)
        pa.descricao_parceria = "Fornecedor/parceiro técnico do projeto #{p[:codigo]}"
      end
    end

    puts new_record ? "CRIADO" : "ATUALIZADO"
  end

  if DRY_RUN
    raise ActiveRecord::Rollback, "DRY_RUN - revertendo transação"
  end
end

puts
puts "=" * 70
puts "Resultado:"
puts "  Demandas elegíveis      : #{Demand.where(aasm_state: 'elegivel').count}"
puts "  Demandas N2 em curso    : #{Demand.where(aasm_state: 'n2_em_andamento').count}"
puts "  LeiDoBemRecord 2025     : #{LeiDoBemRecord.where(ano_base: ANO_BASE).count}"
puts "  Partnerships criadas    : #{Partnership.count}"
puts "  Importados (n2 fonte)   : #{Demand.where("n2_assessment->>'fonte' = ?", FONTE_IMPORT).count}"
puts "=" * 70
puts DRY_RUN ? "[DRY RUN] Nenhuma mudança persistida — rode sem DRY_RUN=true para gravar." : "[OK] Import concluído."

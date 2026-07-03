# Seeds idempotentes - cria 4 usuarios de teste + 4 demandas em estados diferentes
# Senha padrao para todos: Tsuru@2026!

require "ostruct"

PASSWORD = "Tsuru@2026!"

usuarios = [
  { email: "admin@tsuru.local",       name: "Admin Tsuru",        role: :admin },
  { email: "gestor@tsuru.local",      name: "Carlos Gestor",      role: :gestor },
  { email: "analista@tsuru.local",    name: "Carla Analista PD&I", role: :analista_pdi },
  { email: "colaborador@tsuru.local", name: "Roberto Colaborador", role: :colaborador }
]

puts "Criando usuarios..."
usuarios_criados = usuarios.map do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  user.name = attrs[:name]
  user.role = attrs[:role]
  user.password = PASSWORD
  user.password_confirmation = PASSWORD
  user.confirmed_at = Time.current if user.respond_to?(:confirmed_at) # pula confirmable
  user.save!
  puts "  - #{user.email} (#{user.role}) [#{user.persisted? ? 'OK' : 'FAIL'}]"
  user
end

colaborador = usuarios_criados.find { |u| u.colaborador? }

puts "\nCriando demandas de exemplo..."
demandas_sample = [
  {
    title: "Automatizar conferencia de notas fiscais recebidas",
    description: "Hoje a conferencia de cada NF leva 8 minutos e o setor recebe ~120 notas/dia. Ja houve pagamento duplicado por inconsistencia manual. A ideia e integrar com o ERP para puxar NF automaticamente, comparar com pedido de compra e flagar so divergencias para revisao humana.",
    aasm_state: "submetida",
    trl: 4,
    ods_goals: [ 9 ]
  },
  {
    title: "Roteirizacao inteligente de entregas",
    description: "O setor de logistica monta rotas manualmente todo dia, 200+ entregas. A meta e usar otimizacao combinatoria + janela de horarios do cliente para reduzir distancia em ~23% e o tempo P95 de saida.",
    aasm_state: "em_triagem",
    trl: 5,
    ods_goals: [ 9, 13 ]
  },
  {
    title: "Plataforma de monitoramento contínuo de indicadores operacionais",
    description: "Coletar metricas chave do dia-a-dia em tempo real e prever desvios com 24h de antecedencia. Dashboard unificado por area, alertas no celular dos responsaveis.",
    aasm_state: "n2_em_andamento",
    trl: 6,
    ods_goals: [ 9, 11, 13 ]
  },
  {
    title: "Modernizacao do modulo financeiro legado",
    description: "Migrar relatorios financeiros de planilhas para um modulo proprio. E rotina operacional sem barreira tecnica relevante - so reorganizacao de processo.",
    aasm_state: "n1_reprovada",
    trl: nil,
    ods_goals: [],
    n1_flags: { "rotina_operacional" => true, "trl_fora_janela" => true }
  }
]

demandas_sample.each do |attrs|
  next if Demand.exists?(title: attrs[:title])

  flags = attrs.delete(:n1_flags) || {}
  Demand.create!(
    user: colaborador,
    title: attrs[:title],
    description: attrs[:description],
    aasm_state: attrs[:aasm_state],
    trl: attrs[:trl],
    ods_goals: attrs[:ods_goals],
    n1_flags: flags
  )
  puts "  - #{attrs[:title][0..50]} (#{attrs[:aasm_state]})"
end

puts "\nResumo:"
puts "  Usuarios: #{User.count}"
puts "  Demandas: #{Demand.count}"
puts "\nCredenciais (senha unica: #{PASSWORD}):"
usuarios.each { |u| puts "  - #{u[:email].ljust(28)} role=#{u[:role]}" }

# Bloco F — Biblioteca PD&I: artigos de referência (idempotente por título)
admin_user = usuarios_criados.find(&:admin?)

artigos = [
  {
    title: "O que é elegível para a Lei do Bem",
    category: "legislacao",
    body: <<~TXT
      A Lei nº 11.196/2005 (Lei do Bem) concede incentivo fiscal para empresas que investem em
      Pesquisa, Desenvolvimento e Inovação (PD&I) e apuram Lucro Real. O benefício exclui da base
      de cálculo de IRPJ/CSLL entre 60% e 100% dos dispêndios em PD&I, dependendo do incremento
      no número de pesquisadores contratados e da existência de patente/cultivar concedidos no ano-base.

      Elegibilidade não exige ineditismo global. Exige: (a) salto tecnológico em relação ao estado
      da arte anterior — na empresa ou no mercado; (b) incerteza técnica real que justifique o
      consumo de tempo/intelecto/recurso; (c) método científico aplicado (hipóteses, prototipação,
      testes, métricas). Sucesso e fracasso são igualmente válidos como evidência — o que invalida
      um projeto é a previsibilidade trivial (rotina, compliance puro, solução de prateleira sem
      customização, ou maturidade fora da janela de experimentação).
    TXT
  },
  {
    title: "Barreira técnica não é o mesmo que desafio de gestão",
    category: "glossario",
    body: <<~TXT
      A maior causa de glosa é redação fraca, não mérito técnico fraco. Prazo apertado, equipe sem
      treinamento, fornecedor atrasado, orçamento limitado — isso NÃO é Lei do Bem, isso é PMO.

      Barreira técnica é incerteza no domínio da ciência aplicada: limite físico, gargalo
      algorítmico, falha de interoperabilidade, vulnerabilidade arquitetural. Descreva sempre com
      vocabulário técnico-científico e quantificação obrigatória (ms, %, R$, taxas). "Ficou mais
      rápido" é nada; "Redução de latência P99 de 480ms para 87ms sob carga de 50k req/s via
      refatoração do índice composto" é tudo.

      Insucesso conta: hipóteses refutadas e protótipos abandonados, quando documentados com
      justificativa técnica, são a prova mais forte de risco tecnológico genuíno.
    TXT
  },
  {
    title: "Prazos e multas da DIRBI",
    category: "dispendios",
    body: <<~TXT
      A DIRBI (IN RFB 2.198/2024, ampliada por 2.216/2024 e 2.294/2025) é obrigação contínua.
      Lucro Real anual: DIRBI consolidada até 20/02 do ano seguinte. Lucro Real trimestral: DIRBI
      nos meses de encerramento de cada trimestre (mar/jun/set/dez).

      Multa por atraso: 0,5% a 1,5% do faturamento, com teto de 30% do valor do benefício.
      Multa por inexatidão: 3% do valor declarado a maior (mínimo de R$ 500).

      Mantenha ECF, SPED, DIRBI e FORMP&D sempre alinhados — qualquer divergência entre essas
      bases acende malha fiscal automaticamente.
    TXT
  },
  {
    title: "Calendário e regras do FORMP&D 2026",
    category: "formpd",
    body: <<~TXT
      Conforme a Portaria MCTI nº 9.563/2025 (publicada em 03/11/2025), o prazo de entrega do
      FORMP&D foi estendido para 31/08 (não mais 31/07). A avaliação é feita por no mínimo 2
      peritos do CAT em modo cego; havendo divergência, um 3º avaliador sênior decide o desempate.
      Recurso administrativo: 10 dias corridos após o parecer.

      Campos obrigatórios no ciclo 2025/2026: TRL (estágio 1 a 9) e vinculação a pelo menos um
      ODS da Agenda 2030. A integração com a base da RFB é direta — inconsistências entre FORMP&D,
      ECF, SPED e DIRBI são o principal gatilho de fiscalização.
    TXT
  },
  {
    title: "TRL — janela elegível e como estimar",
    category: "trl_ods",
    body: <<~TXT
      TRL (Technology Readiness Level) vai de 1 (princípios básicos observados) a 9 (sistema
      operacional comprovado em ambiente real). A janela tipicamente elegível para Lei do Bem é
      TRL 3 a 7: já saiu da ideação pura, mas ainda não está estabilizado em escala comercial.

      No N2, registre o TRL inicial e final do ano-base com justificativa objetiva — que evidência
      concreta (PoC, bancada, piloto, homologação) sustenta cada nível. TRL 8-9 (sistema pronto e
      qualificado / operação comprovada em produção) tende a indicar fase de implantação, fora do
      escopo do incentivo.
    TXT
  }
].freeze

puts "\nCriando artigos da Biblioteca PD&I..."
artigos.each do |attrs|
  article = KnowledgeArticle.find_or_initialize_by(title: attrs[:title])
  article.category = attrs[:category]
  article.body = attrs[:body].strip
  article.created_by = admin_user
  article.published = true
  article.save!
  puts "  - #{attrs[:title]}"
end

# Bloco I — mapeamentos Sankhya. Entidades/campos CONFIRMADOS por consulta real
# ao gateway em 03/07/2026 (não são nomes de tabela física — a API de negócio do
# Sankhya usa nomes de "entidade" tipo Funcionario/Parceiro/CabecalhoNota, não
# TFPFUN/TGFPAR). Ver Sankhya::Service#consultar e docs/... para o contrato.
sankhya_mappings_seed = [
  { kind: "colaborador",  entidade_sankhya: "Funcionario", campo_codigo: "CODFUNC", campo_nome: "NOMEFUNC", campos_extra: "EMAIL,DTADM,DTDEM,SITUACAO", criterio: nil, enabled: true },
  { kind: "parceiro_pj",  entidade_sankhya: "Parceiro", campo_codigo: "CODPARC", campo_nome: "NOMEPARC", campos_extra: "CGC_CPF,TIPPESSOA,FORNECEDOR", criterio: "this.TIPPESSOA = 'J'", enabled: true },
  # nota_servico: TIPMOV='V' (venda) confirmado funcionar COM this.CODPARC = <id>,
  # mas sozinho (sem parceiro) retorna vazio -- a entidade CabecalhoNota parece
  # exigir um filtro adicional (provavelmente por período; TO_DATE() não é aceito
  # pela linguagem de expressão do Sankhya) para não vir vazia. Desabilitado até
  # descobrir a sintaxe de filtro de data correta.
  { kind: "nota_servico", entidade_sankhya: "CabecalhoNota", campo_codigo: "NUNOTA", campo_nome: "NOMEPARC", campos_extra: "NUMNOTA,DTNEG,VLRNOTA,CODPARC,TIPMOV", criterio: "this.TIPMOV = 'V'", enabled: false },
  # projeto: nenhuma variação testada de nome de entidade (CentroCusto, AD_PROJETOS,
  # TSICCUS, Projeto, etc.) retornou dados nesta instância. Precisa confirmação do
  # nome real com o administrador/DBA Sankhya antes de habilitar.
  { kind: "projeto", entidade_sankhya: "AD_PROJETOS", campo_codigo: "CODPROJETO", campo_nome: "DESCRICAO", campos_extra: "CODCENCUS", criterio: nil, enabled: false }
]
puts "\nCriando/atualizando mapeamentos Sankhya..."
sankhya_mappings_seed.each do |attrs|
  mapping = SankhyaMapping.find_or_initialize_by(kind: attrs[:kind])
  mapping.assign_attributes(attrs)
  mapping.save!
  puts "  - #{SankhyaMapping::KIND_LABELS[attrs[:kind]]} (#{attrs[:enabled] ? 'ativo' : 'pendente'})"
end

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

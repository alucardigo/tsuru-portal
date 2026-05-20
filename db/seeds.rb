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
    title: "IA para triagem automatica de patentes INPI",
    description: "Modelo de NLP que classifica patentes do INPI por classe IPC em < 200ms, reduzindo o tempo de analise manual de 8 horas para 12 minutos. Treinamento em corpus de 50k patentes.",
    aasm_state: "submetida",
    trl: 4,
    ods_goals: [ 9, 17 ]
  },
  {
    title: "Otimizacao de algoritmo de rota logistica",
    description: "Implementacao de algoritmo genetico hibrido para roteirizacao de 200+ entregas/dia. Meta: reduzir distancia total em 23% e tempo P95 de 4h para 2.8h.",
    aasm_state: "em_triagem",
    trl: 5,
    ods_goals: [ 9, 13 ]
  },
  {
    title: "Plataforma de monitoramento ambiental com sensores IoT",
    description: "Rede de sensores LoRaWAN coletando temperatura, umidade e qualidade do ar a cada 30s. Dashboard tempo real com previsao ML 24h adiante (RMSE < 1.5C).",
    aasm_state: "n2_em_andamento",
    trl: 6,
    ods_goals: [ 11, 13, 15 ]
  },
  {
    title: "Refatoracao do modulo financeiro legado",
    description: "Migracao de stored procedures Oracle para microservices Rails. Reescrita de 47k linhas de PL/SQL.",
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

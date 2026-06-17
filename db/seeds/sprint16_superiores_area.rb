# frozen_string_literal: true

# Sprint 16 — superiores vinculados a área (gating por área) + organograma demo.
# Idempotente. Executar: bundle exec rails runner db/seeds/sprint16_superiores_area.rb

PASSWORD = "Tsuru@2026!"

def cria_superior(nome, email, area)
  u = User.find_or_initialize_by(email: email)
  u.name = nome
  u.role = :gestor
  u.area = area
  u.active = true
  if u.new_record?
    u.password = PASSWORD
    u.password_confirmation = PASSWORD
  end
  u.confirmed_at ||= Time.current if u.respond_to?(:confirmed_at)
  u.save!
  puts "  superior: #{u.email.ljust(28)} área=#{u.area}"
  u
end

puts "== Superiores por área =="
fernanda = cria_superior("Fernanda Superior Financeiro", "fernanda@tsuru.local", "Financeiro")
daniela  = cria_superior("Daniela Superior Logística",   "daniela@tsuru.local",  "Logística / Suprimentos")
karina   = cria_superior("Karina Superior Comercial",    "karina@tsuru.local",   "Comercial")

# Carlos Gestor (demo já existente) recebe uma área
carlos = User.find_by(email: "gestor@tsuru.local")
if carlos
  carlos.update!(area: "Operacional") if carlos.area.blank?
  puts "  superior: #{carlos.email.ljust(28)} área=#{carlos.area}"
end

# Vincula equipe (superior direto) para popular o organograma
puts "\n== Vínculos de equipe (organograma) =="
{
  "colaborador@tsuru.local"  => daniela,
  "suporteti@bellube.com.br" => karina
}.each do |email, sup|
  u = User.find_by(email: email)
  next unless u && sup
  u.update!(supervisor_id: sup.id)
  puts "  #{u.email} -> superior #{sup.display_name}"
end

puts "\n== Resumo =="
User.where(role: :gestor).ativos.order(:area).each do |g|
  puts "  #{(g.area.presence || '(sem área)').ljust(24)} #{g.display_name}"
end
puts "[OK] Superiores e áreas configurados."

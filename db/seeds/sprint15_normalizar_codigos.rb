# frozen_string_literal: true

# Sprint 15 — padroniza o formato dos códigos INOVA BEL existentes (sem usar DEM).
# Mantém o NÚMERO real de cada projeto; só uniformiza a grafia para "INOVA BEL-0XX".
#  - "INOVA BEL 005"                  -> "INOVA BEL-005"
#  - "INOVA BEL007"                   -> "INOVA BEL-007"
#  - "INOVA BEL-005.1(Sub ONSIG RH)"  -> "INOVA BEL-005.1"
#  - "INOVA BEL 001/2"                -> "INOVA BEL-001/2"
# Idempotente. Executar: bundle exec rails runner db/seeds/sprint15_normalizar_codigos.rb

def normalizar(codigo)
  return codigo if codigo.blank?
  c = codigo.gsub(/\s*\(.*?\)\s*/, "").strip      # remove descritor "(Sub ONSIG RH)"
  c = c.sub(/\AINOVA\s*BEL[\s\-]*/i, "INOVA BEL-") # uniformiza prefixo -> "INOVA BEL-"
  c
end

puts "== Padronização de códigos INOVA BEL =="
alterados = 0
Demand.where.not(codigo: nil).order(:id).each do |d|
  novo = normalizar(d.codigo)
  next if novo == d.codigo
  # libera destino se ocupado por outro
  Demand.where(codigo: novo).where.not(id: d.id).update_all(codigo: nil)
  antigo = d.codigo
  d.update_columns(codigo: novo)
  puts "  #{antigo}  ->  #{novo}"
  alterados += 1
end
puts "  #{alterados} código(s) padronizado(s)"

puts "\n== Portfólio final =="
Demand.where.not(codigo: nil).order(:numero_inova, :id).each do |d|
  puts "  #{d.codigo.ljust(16)} #{d.title.to_s[0, 48]}"
end
puts "[OK] Códigos padronizados (sem DEM)."

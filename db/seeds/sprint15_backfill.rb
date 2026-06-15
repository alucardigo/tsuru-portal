# frozen_string_literal: true

# ============================================================
# Sprint 15 — backfill do fluxo INOVA BEL (idempotente)
#   1. Cria usuário FI Group (login próprio) + supervisor demo
#   2. Backfill do código INOVA BEL em demandas existentes
#   3. Re-mapeia legados pelo status FI (13 elegíveis -> Projeto de Fato)
# Executar: bundle exec rails runner db/seeds/sprint15_backfill.rb
# ============================================================

PASSWORD = "Tsuru@2026!"

puts "== 1. Usuário FI Group =="
fi = User.find_or_initialize_by(email: "fi@tsuru.local")
fi.name = "Consultoria FI Group"
fi.role = :fi
fi.area = "Consultoria externa"
fi.active = true
fi.password = PASSWORD if fi.new_record?
fi.password_confirmation = PASSWORD if fi.new_record?
fi.confirmed_at ||= Time.current if fi.respond_to?(:confirmed_at)
fi.save!
puts "  fi@tsuru.local (#{fi.role}) OK"

# Vínculo de superior (demo): colaborador -> gestor
colab = User.find_by(email: "colaborador@tsuru.local")
gestor = User.find_by(email: "gestor@tsuru.local")
if colab && gestor && colab.supervisor_id.nil?
  colab.update!(supervisor_id: gestor.id)
  puts "  vínculo: #{colab.email} -> supervisor #{gestor.email}"
end

puts "\n== 2. Backfill código INOVA BEL =="

def numero_livre?(numero, exclude_id)
  numero.present? && !Demand.where(numero_inova: numero).where.not(id: exclude_id).exists?
end

# 2a) Legados com codigo_legado em n2_assessment
legados = 0
Demand.where(codigo: nil).find_each do |d|
  assessment = d.n2_assessment
  legado = assessment.is_a?(Hash) ? assessment["codigo_legado"] : nil
  next if legado.blank?

  numero = legado[/(\d+)/, 1]&.to_i
  numero = nil unless numero_livre?(numero, d.id)
  d.update_columns(codigo: legado, numero_inova: numero)
  legados += 1
end
puts "  #{legados} demandas legadas receberam código original"

# 2b) Demais demandas já submetidas (não rascunho) sem código -> sequencial
sequenciais = 0
Demand.where(codigo: nil).where.not(aasm_state: "rascunho").order(:id).find_each do |d|
  proximo = (Demand.maximum(:numero_inova) || 0) + 1
  d.update_columns(codigo: format("INOVA BEL-%03d", proximo), numero_inova: proximo)
  sequenciais += 1
end
puts "  #{sequenciais} demandas submetidas receberam código sequencial"

puts "\n== 3. Re-mapeamento legados pelo status FI =="
# 13 demandas elegíveis (parecer FI positivo) viram Projeto de Fato.
remap = 0
Demand.where(aasm_state: "elegivel").find_each do |d|
  fonte = d.n2_assessment.is_a?(Hash) ? d.n2_assessment["fonte"] : nil
  next unless fonte == "import_lei_do_bem_2025"

  d.update_columns(aasm_state: "projeto")
  DemandTransition.create!(
    demand: d, actor: fi, from_state: "elegivel", to_state: "projeto",
    event: "tornar_projeto", justification: "Re-mapeamento Sprint 15 — FI já avaliou como elegível.",
    created_at: Time.current
  )
  remap += 1
end
puts "  #{remap} elegíveis legados promovidos a Projeto INOVA BEL"

puts "\n== Resumo =="
puts "  Usuários: #{User.count} (FI: #{User.where(role: :fi).count})"
puts "  Com código INOVA: #{Demand.where.not(codigo: nil).count}/#{Demand.count}"
puts "  Projetos de fato: #{Demand.where(aasm_state: 'projeto').count}"
puts "  Em avaliação FI: #{Demand.where(aasm_state: 'em_avaliacao_fi').count}"
puts "[OK] Backfill Sprint 15 concluído."

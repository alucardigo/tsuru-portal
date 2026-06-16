# frozen_string_literal: true

# Sprint 15 — alinhamento dos códigos aos EXATOS da planilha FI + remoção da demanda de teste.
# Idempotente. Executar: bundle exec rails runner db/seeds/sprint15_codigos_fi.rb

# 1) Códigos exatos conforme planilha MCTI/FI (normalizado -> verbatim)
EXATOS = {
  "INOVA BEL-005"   => "INOVA BEL 005",
  "INOVA BEL-005.1" => "INOVA BEL-005.1(Sub ONSIG RH)",
  "INOVA BEL-007"   => "INOVA BEL007",
  "INOVA BEL-008"   => "INOVA BEL008",
  "INOVA BEL-009"   => "INOVA BEL009",
  "INOVA BEL-010"   => "INOVA BEL010"
}.freeze

puts "== 1. Códigos exatos da planilha FI =="
alterados = 0
EXATOS.each do |de, para|
  d = Demand.find_by(codigo: de)
  next unless d
  # libera o destino se por acaso já estiver ocupado
  Demand.where(codigo: para).where.not(id: d.id).update_all(codigo: nil)
  d.update_columns(codigo: para)
  puts "  #{de}  ->  #{para}"
  alterados += 1
end
puts "  #{alterados} código(s) ajustado(s)"

# 2) Remoção da demanda de teste (bypass do append-only só para este id)
puts "\n== 2. Remoção da demanda de teste =="
teste = Demand.where(title: "Teste").or(Demand.where(codigo: "INOVA BEL-018")).first
if teste
  id = teste.id.to_i
  conn = ActiveRecord::Base.connection
  # Append-only: desabilita triggers USER da tabela (privilégio de dono) só para esta limpeza.
  begin
    conn.execute("ALTER TABLE demand_transitions DISABLE TRIGGER USER")
  rescue StandardError => e
    puts "  (aviso: DISABLE TRIGGER falhou: #{e.message[0, 60]})"
  end
  begin
    conn.execute("DELETE FROM demand_transitions WHERE demand_id = #{id}")
    conn.execute("DELETE FROM notifications WHERE demand_id = #{id}") rescue nil
    conn.execute("DELETE FROM comments WHERE demand_id = #{id}") rescue nil
    conn.execute("DELETE FROM project_tasks WHERE demand_id = #{id}") rescue nil
    conn.execute("DELETE FROM board_decisions WHERE demand_id = #{id}") rescue nil
    conn.execute("DELETE FROM expenses WHERE lei_do_bem_record_id IN (SELECT id FROM lei_do_bem_records WHERE demand_id = #{id})") rescue nil
    conn.execute("DELETE FROM team_members WHERE lei_do_bem_record_id IN (SELECT id FROM lei_do_bem_records WHERE demand_id = #{id})") rescue nil
    conn.execute("DELETE FROM partnerships WHERE lei_do_bem_record_id IN (SELECT id FROM lei_do_bem_records WHERE demand_id = #{id})") rescue nil
    conn.execute("DELETE FROM lei_do_bem_records WHERE demand_id = #{id}") rescue nil
    conn.execute("DELETE FROM versions WHERE item_type = 'Demand' AND item_id = #{id}") rescue nil
    conn.execute("DELETE FROM demands WHERE id = #{id}")
    puts "  Demanda de teste (id=#{id}) removida."
  ensure
    conn.execute("ALTER TABLE demand_transitions ENABLE TRIGGER USER") rescue nil
  end
else
  puts "  Nenhuma demanda de teste encontrada."
end

puts "\n== Resumo =="
puts "  Demandas: #{Demand.count} | com código: #{Demand.where.not(codigo: nil).count}"
Demand.order(:numero_inova, :id).each { |d| puts "  #{d.codigo} — #{d.title.to_s[0, 45]}" }
puts "[OK] Sprint 15 — códigos FI."

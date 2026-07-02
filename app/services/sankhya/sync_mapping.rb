# frozen_string_literal: true

# Bloco I — Sincroniza um SankhyaMapping: consulta a entidade configurada no
# gateway Sankhya e faz upsert em SankhyaRecord (cache local). Rodado manualmente
# via /admin/sankhya (jobs agendados exigem o Solid Queue rodando, débito conhecido).
module Sankhya
  module SyncMapping
    Result = Struct.new(:ok, :count, :error, keyword_init: true) do
      def success? = ok
    end

    module_function

    def call(mapping, service: Sankhya::Service.new)
      rows = service.consultar(entidade: mapping.entidade_sankhya, campos: mapping.campos_lista, criterio: mapping.criterio)

      count = 0
      SankhyaRecord.transaction do
        rows.each do |row|
          codigo = row[mapping.campo_codigo].to_s
          next if codigo.blank?

          record = mapping.sankhya_records.find_or_initialize_by(codigo: codigo)
          record.nome = row[mapping.campo_nome]
          record.raw_data = row
          record.synced_at = Time.current
          record.save!
          count += 1
        end
      end

      mapping.update!(last_synced_at: Time.current, last_sync_count: count, last_sync_error: nil)
      Result.new(ok: true, count: count)
    rescue StandardError => e
      mapping.update!(last_synced_at: Time.current, last_sync_error: e.message.to_s.truncate(500))
      Result.new(ok: false, error: e.message)
    end
  end
end

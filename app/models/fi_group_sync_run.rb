# frozen_string_literal: true

# Registro de auditoria de cada rodada do autosync FI Group (cron ou manual).
# Uma linha por execução; guarda contadores e erros para diagnóstico.
class FiGroupSyncRun < ApplicationRecord
  self.table_name = "figroup_sync_runs"

  scope :recent, ->(n = 50) { order(started_at: :desc).limit(n) }

  # Última rodada com token válido (para exibir "último sync OK").
  def self.last_ok
    where(token_ok: true).order(started_at: :desc).first
  end

  # Duração em segundos, se a rodada terminou.
  def duration_seconds
    return nil unless finished_at && started_at

    finished_at - started_at
  end

  # Rodada saudável: token validou e não houve erros.
  # Usa error_details (coluna JSONB); "errors" é reservado por ActiveModel.
  def ok?
    token_ok && Array(error_details).empty?
  end
end

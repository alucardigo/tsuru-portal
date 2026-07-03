# frozen_string_literal: true

# Auditoria de execuções do autosync (cron) + settings singleton + flag de push pendente.
class CreateFigroupAutosync < ActiveRecord::Migration[8.1]
  def change
    # Histórico de cada rodada do autosync (uma linha por execução do cron/manual).
    create_table :figroup_sync_runs do |t|
      t.datetime :started_at
      t.datetime :finished_at
      t.boolean  :token_ok, default: false
      t.string   :trigger, default: "cron"
      t.integer  :pulled_count, default: 0
      t.integer  :linked_count, default: 0
      t.integer  :pushed_count, default: 0
      # NÃO nomear a coluna "errors": colide com ActiveModel::Errors (run.errors
      # continuaria retornando o objeto de validação, não o JSONB). Ver FiGroupSyncRun.
      t.jsonb    :error_details, default: []

      t.timestamps
    end

    add_index :figroup_sync_runs, :started_at

    # Configuração singleton do autosync.
    create_table :figroup_settings do |t|
      t.boolean  :auto_sync_enabled, default: true, null: false
      t.datetime :last_expiry_notified_at

      t.timestamps
    end

    # Marca projetos com conteúdo N2 pendente de push (Tsuru -> FI).
    add_column :figroup_projects, :push_pending, :boolean, default: false, null: false
    add_index :figroup_projects, :push_pending
  end
end

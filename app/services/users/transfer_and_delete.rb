# frozen_string_literal: true

# Bloco M — Transfere tudo que um usuário possui para outro (desligamento/realocação)
# e então apaga a conta. Reusa o padrão da limpeza de usuários fake de 02/07/2026.
module Users
  module TransferAndDelete
    # Tabelas de OWNERSHIP (autoria/responsabilidade) — reatribuídas ao usuário destino.
    OWNERSHIP = {
      "demands" => "user_id",
      "comments" => "user_id",
      "demand_transitions" => "actor_id",
      "project_tasks" => "creator_id",
      "project_task_comments" => "user_id",
      "team_members" => "user_id",
      "project_task_time_entries" => "user_id",
      "defense_dossiers" => "created_by_id",
      "knowledge_articles" => "created_by_id",
      "ai_reports" => "requested_by_id",
    }.freeze

    # Tabelas de PARTICIPAÇÃO (join/preferência) — removidas em vez de reatribuídas,
    # pra não violar unique index se o destino já participa do mesmo registro.
    MEMBERSHIP = {
      "project_task_watchers" => "user_id",
      "project_task_assignees" => "user_id",
      "project_task_comment_reactions" => "user_id",
      "saved_task_views" => "user_id",
      "notifications" => "recipient_id",
    }.freeze

    module_function

    # Retorna contagem de registros afetados, sem alterar nada — usado na tela de confirmação.
    def preview(source)
      counts = {}
      OWNERSHIP.each do |table, col|
        n = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{table} WHERE #{col} = #{source.id}").to_i
        counts[table] = n if n.positive?
      end
      counts[:project_tasks_assignee] = ProjectTask.where(assignee_id: source.id).count
      counts.delete(:project_tasks_assignee) if counts[:project_tasks_assignee].zero?
      MEMBERSHIP.each do |table, col|
        n = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{table} WHERE #{col} = #{source.id}").to_i
        counts["#{table}_removidos"] = n if n.positive?
      end
      counts[:subordinados] = User.where(supervisor_id: source.id).count
      counts.delete(:subordinados) if counts[:subordinados].zero?
      counts
    end

    def call(source:, target:)
      raise ArgumentError, "origem e destino não podem ser o mesmo usuário" if source.id == target.id

      ActiveRecord::Base.transaction do
        OWNERSHIP.each do |table, col|
          ActiveRecord::Base.connection.execute("UPDATE #{table} SET #{col} = #{target.id} WHERE #{col} = #{source.id}")
        end
        ProjectTask.where(assignee_id: source.id).update_all(assignee_id: target.id)
        MEMBERSHIP.each do |table, col|
          ActiveRecord::Base.connection.execute("DELETE FROM #{table} WHERE #{col} = #{source.id}")
        end
        User.where(supervisor_id: source.id).update_all(supervisor_id: nil)
        source.destroy!
      end
      true
    end
  end
end

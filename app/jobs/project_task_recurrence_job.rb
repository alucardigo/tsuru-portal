# frozen_string_literal: true

# Sprint 27 — gera a próxima ocorrência de tarefas recorrentes.
# Roda diariamente via config/recurring.yml (Solid Queue).
# A tarefa "mãe" guarda {kind, next_at}; quando next_at vence, clonamos a
# tarefa com due_date = next_at e avançamos o ponteiro. Cópias não recorrem.
class ProjectTaskRecurrenceJob < ApplicationJob
  queue_as :default

  INTERVALS = { "daily" => 1, "weekly" => 7, "monthly" => 30 }.freeze

  def perform
    ProjectTask.where.not(recurrence: nil).find_each do |task|
      rec = task.recurrence
      next if rec.blank? || rec["kind"].blank?
      interval = INTERVALS[rec["kind"]] or next
      next_at = (Date.parse(rec["next_at"].to_s) rescue nil) or next
      next if next_at > Date.current

      task.demand.tasks.create!(
        title:           task.title,
        description:     task.description,
        priority:        task.priority,
        kanban_status:   "backlog",
        creator:         task.creator,
        assignee:        task.assignee,
        estimated_hours: task.estimated_hours,
        spent_hours:     0,
        due_date:        next_at,
        custom_fields:   task.custom_fields || {}
      )
      task.update!(recurrence: rec.merge("next_at" => (next_at + interval.days).to_s))
    rescue StandardError => e
      Rails.logger.warn("[RecurrenceJob] task=#{task.id} #{e.class}: #{e.message}")
    end
  end
end

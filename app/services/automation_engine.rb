# frozen_string_literal: true

# Avalia automações quando um evento acontece numa tarefa.
# Uso: AutomationEngine.fire(:"task.completed", task)
module AutomationEngine
  module_function

  def fire(event_key, task)
    return unless task && task.demand_id
    automations = TaskAutomation.enabled
                                .where(trigger_event: event_key.to_s)
                                .for_demand(task.demand)
    automations.each { |a| dispatch(a, task) }
  rescue StandardError => e
    Rails.logger.warn("[AutomationEngine] fired=#{event_key} task=#{task&.id} error=#{e.class}: #{e.message}")
  end

  def dispatch(automation, task)
    case automation.action_kind
    when "notify_assignees_of_dependents"
      task.successors.where.not(assignee_id: nil).find_each do |dep|
        Notification.create!(
          user_id: dep.assignee_id,
          kind:    "automation",
          message: "Predecessora \"#{task.title}\" foi concluída — você pode iniciar \"#{dep.title}\".",
          link_path: Rails.application.routes.url_helpers.kanban_demand_tasks_path(task.demand_id)
        )
      end
    when "notify_assignee"
      return unless task.assignee_id
      Notification.create!(
        user_id: task.assignee_id,
        kind: "automation",
        message: "Automação \"#{automation.name}\" disparada em \"#{task.title}\"",
        link_path: Rails.application.routes.url_helpers.kanban_demand_tasks_path(task.demand_id)
      )
    when "notify_supervisors"
      area = task.demand.try(:area_impactada)
      return unless area
      User.where(role: :gestor, area: area).find_each do |sup|
        Notification.create!(
          user_id: sup.id, kind: "automation",
          message: "Automação na área #{area}: \"#{task.title}\"",
          link_path: Rails.application.routes.url_helpers.kanban_demand_tasks_path(task.demand_id)
        )
      end
    end
  end
end

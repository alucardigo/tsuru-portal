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
    link = Rails.application.routes.url_helpers.kanban_demand_tasks_path(task.demand_id)
    case automation.action_kind
    when "notify_assignees_of_dependents"
      task.successors.where.not(assignee_id: nil).find_each do |dep|
        notify(dep.assignee_id, task.demand_id,
               "Predecessora concluída",
               "Você pode iniciar \"#{dep.title}\" — predecessora \"#{task.title}\" foi concluída.",
               link)
      end
    when "notify_assignee"
      return unless task.assignee_id
      notify(task.assignee_id, task.demand_id,
             "Automação: #{automation.name}",
             "Disparada em \"#{task.title}\"",
             link)
    when "notify_supervisors"
      area = task.demand.try(:area_impactada)
      return unless area
      User.where(role: :gestor, area: area).find_each do |sup|
        notify(sup.id, task.demand_id,
               "Automação na área #{area}",
               "Tarefa: \"#{task.title}\"",
               link)
      end
    end
  end

  def notify(recipient_id, demand_id, title, body, link_path)
    Notification.create!(
      recipient_id: recipient_id,
      demand_id:    demand_id,
      kind:         "automation",
      title:        title,
      body:         body,
      payload:      { link_path: link_path }
    )
  end
end

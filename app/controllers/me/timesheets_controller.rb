# frozen_string_literal: true

# /me/timesheet — relatório semanal de tempo cronometrado x tempo decorrido.
# Mostra o "gap" entre cycle time (atribuição → conclusão) e active time (cronômetro).
module Me
  class TimesheetsController < ApplicationController
    before_action :authenticate_user!

    def show
      @ref_date = parse_date(params[:date]) || Date.current
      @week_start = @ref_date.beginning_of_week(:monday)
      @week_end   = @ref_date.end_of_week(:monday)

      entries = ProjectTaskTimeEntry
                  .where(user_id: current_user.id)
                  .where("project_task_time_entries.started_at >= ? AND project_task_time_entries.started_at < ?", @week_start, @week_end + 1)
                  .includes(project_task: :demand)

      @by_day = (0..6).map { |i| @week_start + i.days }.index_with { [] }
      entries.each do |e|
        day = e.started_at.to_date
        @by_day[day] ||= []
        @by_day[day] << e
      end

      @total_secs        = entries.where.not(duration_seconds: nil).sum(:duration_seconds).to_i
      @entries_open      = entries.where(ended_at: nil).count
      @tasks_distinct    = entries.pluck(:project_task_id).uniq.size
      @projects_distinct = entries.map { |e| e.project_task.demand_id }.uniq.size

      # Cruzamento cycle vs active — tarefas onde a discrepância é maior
      tasks_with_lead = ProjectTask.where(assignee_id: current_user.id).where.not(assigned_at: nil)
      @discrepancia = tasks_with_lead.map do |t|
        lead   = t.lead_time_seconds.to_i
        active = t.active_seconds.to_i
        gap_pct = lead.zero? ? 0 : (((lead - active).to_f / lead) * 100).round
        { task: t, lead: lead, active: active, gap_pct: gap_pct }
      end.sort_by { |h| -h[:gap_pct] }.first(10)
    end

    private

    def parse_date(s)
      Date.parse(s) rescue nil
    end
  end
end

# frozen_string_literal: true

# /demands/:demand_id/tasks/calendar — visão calendário mensal por due_date.
class ProjectTaskCalendarsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_demand

  def show
    @ref  = Date.parse(params[:date]) rescue Date.current
    @month_start = @ref.beginning_of_month
    @month_end   = @ref.end_of_month
    grid_start   = @month_start.beginning_of_week(:sunday)
    grid_end     = @month_end.end_of_week(:sunday)
    @grid_days   = (grid_start..grid_end).to_a

    scope = @demand.tasks.where.not(due_date: nil)
                          .where(due_date: grid_start..grid_end)
                          .includes(:assignee)
    @tasks_by_day = scope.group_by(&:due_date)
  end

  private

  def set_demand
    @demand = Demand.find(params[:demand_id])
  end
end

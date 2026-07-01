# frozen_string_literal: true

class SearchController < ApplicationController
  before_action :authenticate_user!

  # GET /search/quick?q=... → JSON com demandas, tasks, users
  def quick
    q = params[:q].to_s.strip
    if q.length < 2
      render json: { demands: [], tasks: [], users: [] } and return
    end
    like = "%#{ActiveRecord::Base.sanitize_sql_like(q)}%"

    demands = policy_scope(Demand).where("title ILIKE :q OR codigo ILIKE :q", q: like).limit(6).map do |d|
      { id: d.id, title: d.title.to_s.truncate(80), codigo: d.codigo_display, path: demand_path(d) }
    end

    tasks = ProjectTask.joins(:demand)
                       .where("project_tasks.title ILIKE ?", like)
                       .where(demands: { id: policy_scope(Demand).select(:id) })
                       .limit(8).map do |t|
      { id: t.id, title: t.title.to_s.truncate(80), demand: t.demand.codigo_display,
        path: edit_demand_task_path(t.demand_id, t) }
    end

    users = User.ativos.where("name ILIKE :q OR email ILIKE :q", q: like).limit(5).map do |u|
      { id: u.id, name: u.display_name, email: u.email, role: u.role, path: "/admin/users" }
    end

    render json: { demands: demands, tasks: tasks, users: users }
  end
end

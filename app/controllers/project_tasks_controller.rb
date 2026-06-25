# frozen_string_literal: true

class ProjectTasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_demand
  before_action :set_task, only: %i[edit update destroy move]
  before_action :authorize_task!, except: %i[index kanban new create]
  before_action :authorize_collection!, only: %i[index kanban new create]

  def index
    @tasks = @demand.tasks.includes(:assignee, :creator).by_kanban
  end

  def kanban
    @tasks_by_status = @demand.tasks.includes(:assignee).by_kanban.group_by(&:kanban_status)
    @statuses        = ProjectTask::KANBAN_STATUSES
    @metricas        = build_metricas
  end

  def new
    @task = @demand.tasks.build(kanban_status: params[:kanban_status].presence || "backlog",
                                creator: current_user,
                                priority: "media")
  end

  def create
    @task = @demand.tasks.build(task_params)
    @task.creator = current_user
    @task.position = next_position_for(@task.kanban_status)
    if @task.save
      redirect_to kanban_demand_tasks_path(@demand), notice: "Tarefa criada."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @task.update(task_params)
      redirect_to kanban_demand_tasks_path(@demand), notice: "Tarefa atualizada."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @task.destroy!
    redirect_to kanban_demand_tasks_path(@demand), notice: "Tarefa removida."
  end

  # Drag-and-drop: muda status (coluna) e/ou posição da task no kanban
  def move
    new_status = params[:kanban_status].presence_in(ProjectTask::KANBAN_STATUSES) || @task.kanban_status
    new_position = params[:position].to_i

    ProjectTask.transaction do
      # afasta as outras na coluna de destino para abrir o slot
      @demand.tasks.where(kanban_status: new_status)
             .where("position >= ?", new_position)
             .where.not(id: @task.id)
             .update_all("position = position + 1")
      @task.update!(kanban_status: new_status, position: new_position)
    end

    respond_to do |fmt|
      fmt.json { render json: { ok: true, kanban_status: @task.kanban_status, position: @task.position } }
      fmt.turbo_stream { head :ok }
      fmt.html { redirect_to kanban_demand_tasks_path(@demand) }
    end
  end

  private

  def set_demand
    @demand = Demand.find(params[:demand_id])
  end

  def set_task
    @task = @demand.tasks.find(params[:id])
  end

  def authorize_task!
    authorize(@task, policy_class: ProjectTaskPolicy)
  end

  def authorize_collection!
    # Permissao baseada em uma task "virtual" no demand para reusar a policy
    sample = @demand.tasks.first || ProjectTask.new(demand: @demand, creator: current_user)
    authorize(sample, :index?, policy_class: ProjectTaskPolicy)
  rescue Pundit::NotAuthorizedError
    redirect_to demand_path(@demand), alert: "Sem permissão para tarefas deste projeto." and return
  end

  def task_params
    params.require(:project_task).permit(:title, :description, :kanban_status, :priority,
                                         :estimated_hours, :spent_hours, :due_date, :assignee_id, :parent_id,
                                         :sprint_id, :story_points,
                                         attachments: [])
  end

  def next_position_for(status)
    (@demand.tasks.where(kanban_status: status).maximum(:position) || -1) + 1
  end

  def build_metricas
    total = @demand.tasks.count
    {
      total: total,
      concluidas: @demand.tasks.where(kanban_status: "concluida").count,
      em_andamento: @demand.tasks.where(kanban_status: %w[em_andamento em_revisao]).count,
      atrasadas: @demand.tasks.atrasadas.count,
      horas_estimadas: @demand.tasks.sum(:estimated_hours).to_f,
      horas_gastas: @demand.tasks.sum(:spent_hours).to_f
    }
  end
end

# frozen_string_literal: true

class ProjectTasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_demand
  before_action :set_task, only: %i[edit update destroy move reassign]
  before_action :authorize_task!, except: %i[index kanban new create]
  before_action :authorize_collection!, only: %i[index kanban new create]

  def index
    @tasks = @demand.tasks.includes(:assignee, :creator).by_kanban
  end

  def kanban
    @tasks_by_status = @demand.tasks.includes(:assignee).by_kanban.group_by(&:kanban_status)
    custom = @demand.task_workflow_states
    @statuses        = custom.present? ? custom.map { |s| s["key"] } : ProjectTask::KANBAN_STATUSES
    @status_labels   = custom.present? ? custom.each_with_object({}) { |s, h| h[s["key"]] = s["label"] } : {}
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

  # Sprint 24 — Transferir tarefa com handoff note (estilo Wrike).
  # Mudar assignee + adicionar comentário automático + notif para novo responsável.
  def reassign
    new_assignee_id = params[:assignee_id].presence
    note = params[:handoff_note].to_s.strip
    old_user = @task.assignee
    new_user = User.find_by(id: new_assignee_id)

    if new_assignee_id.blank? || new_user.nil?
      redirect_back fallback_location: edit_demand_task_path(@demand, @task), alert: "Selecione um responsável válido." and return
    end
    if new_user.id == old_user&.id
      redirect_back fallback_location: edit_demand_task_path(@demand, @task), alert: "Mesmo responsável." and return
    end

    @task.update!(assignee: new_user)

    handoff_body = if old_user
      "🔁 Transferido por #{current_user.display_name}: #{old_user.display_name} → #{new_user.display_name}#{note.present? ? "\n\n#{note}" : ''}"
    else
      "🔁 Atribuído a #{new_user.display_name} por #{current_user.display_name}#{note.present? ? "\n\n#{note}" : ''}"
    end
    @task.comments.create!(user: current_user, body: handoff_body)

    Notification.create!(
      recipient_id: new_user.id, demand_id: @demand.id, kind: "task_handoff",
      title: "Você recebeu uma tarefa",
      body: "#{current_user.display_name} atribuiu \"#{@task.title.to_s.truncate(50)}\" a você",
      payload: { link_path: edit_demand_task_path(@demand, @task) }
    )

    redirect_back fallback_location: edit_demand_task_path(@demand, @task), notice: "Tarefa transferida para #{new_user.display_name}."
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
    permitted = params.require(:project_task).permit(:title, :description, :kanban_status, :priority,
                                         :estimated_hours, :spent_hours, :due_date, :assignee_id, :parent_id,
                                         :sprint_id, :story_points,
                                         attachments: [], custom_fields: {})
    # Sanitize custom_fields keys against the demand's field definitions
    defs = @demand&.task_field_definitions || []
    allowed_keys = defs.map { |d| d["key"] }
    if permitted[:custom_fields].present?
      permitted[:custom_fields] = permitted[:custom_fields].to_h.slice(*allowed_keys)
    end
    permitted
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

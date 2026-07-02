# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ProjectTasksController < BaseController
        before_action :set_task, only: %i[show update]

        def index
          scope = ProjectTask.all
          scope = scope.where(demand_id: params[:demand_id]) if params[:demand_id].present?
          scope = scope.where(kanban_status: params[:status]) if params[:status].present?
          scope = scope.where(assignee_id: params[:assignee_id]) if params[:assignee_id].present?
          render json: paginate(scope.order(created_at: :desc)).map { |t| serialize(t) }
        end

        def show
          render json: serialize(@task, detailed: true)
        end

        def create
          demand = Demand.find(params.require(:demand_id))
          task = demand.tasks.build(create_params.merge(creator: @current_api_user))
          if task.save
            render json: serialize(task), status: :created
          else
            render json: { error: task.errors.full_messages.join(", ") }, status: :unprocessable_content
          end
        end

        def update
          if @task.update(update_params)
            render json: serialize(@task)
          else
            render json: { error: @task.errors.full_messages.join(", ") }, status: :unprocessable_content
          end
        end

        private

        def set_task
          @task = ProjectTask.find(params[:id])
        end

        def create_params
          params.permit(:title, :description, :kanban_status, :priority, :assignee_id, :due_date)
                .with_defaults(kanban_status: "backlog", priority: "media")
        end

        def update_params
          params.permit(:title, :description, :kanban_status, :priority, :assignee_id, :due_date)
        end

        def serialize(task, detailed: false)
          base = {
            id: task.id, title: task.title, status: task.kanban_status, priority: task.priority,
            demand_id: task.demand_id, assignee_id: task.assignee_id, due_date: task.due_date
          }
          return base unless detailed

          base.merge(description: task.description, creator_id: task.creator_id,
                     comments_count: task.comments.count)
        end
      end
    end
  end
end

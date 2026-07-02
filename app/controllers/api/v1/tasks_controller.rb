# frozen_string_literal: true

# Bloco H — API de entrada para integrações externas (Power Automate/Zapier/n8n) criarem
# tarefas ou comentários no Tsuru via HTTP, autenticado por token pessoal.
module Api
  module V1
    class TasksController < BaseController
      def create
        demand = Demand.find_by(id: params[:demand_id])
        return render json: { error: "demand_id inválido" }, status: :unprocessable_content unless demand

        task = demand.tasks.build(
          title: params.require(:title),
          description: params[:description],
          kanban_status: params[:kanban_status].presence_in(ProjectTask::KANBAN_STATUSES) || "backlog",
          priority: params[:priority].presence_in(ProjectTask::PRIORITIES) || "media",
          creator: @current_api_user,
          assignee: assignee_from_param
        )

        if task.save
          render json: { id: task.id, title: task.title, status: task.kanban_status }, status: :created
        else
          render json: { error: task.errors.full_messages.join(", ") }, status: :unprocessable_content
        end
      end

      def create_comment
        task = ProjectTask.find_by(id: params[:id])
        return render json: { error: "tarefa não encontrada" }, status: :not_found unless task

        comment = task.comments.build(user: @current_api_user, body: params.require(:body))
        if comment.save
          render json: { id: comment.id }, status: :created
        else
          render json: { error: comment.errors.full_messages.join(", ") }, status: :unprocessable_content
        end
      end

      private

      def assignee_from_param
        return nil if params[:assignee_email].blank?

        User.find_by(email: params[:assignee_email])
      end
    end
  end
end

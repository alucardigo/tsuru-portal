# frozen_string_literal: true

module Api
  module V1
    module Admin
      class UsersController < BaseController
        before_action :set_user, only: %i[show update destroy]

        def index
          scope = User.all
          scope = scope.where(role: params[:role]) if params[:role].present?
          scope = scope.where(area: params[:area]) if params[:area].present?
          scope = scope.ativos   if params[:status] == "ativos"
          scope = scope.inativos if params[:status] == "inativos"
          if params[:q].present?
            like = "%#{User.sanitize_sql_like(params[:q])}%"
            scope = scope.where("name ILIKE :q OR email ILIKE :q", q: like)
          end
          render json: paginate(scope.order(:name, :email)).map { |u| serialize(u) }
        end

        def show
          render json: serialize(@user, detailed: true)
        end

        def create
          user = User.new(create_params)
          user.password = params.dig(:user, :password).presence || SecureRandom.base58(16)
          user.confirmed_at = Time.current
          if user.save
            render json: serialize(user), status: :created
          else
            render json: { error: user.errors.full_messages.join(", ") }, status: :unprocessable_content
          end
        end

        def update
          if @user.update(update_params)
            render json: serialize(@user)
          else
            render json: { error: @user.errors.full_messages.join(", ") }, status: :unprocessable_content
          end
        end

        # Reatribui tudo que o usuario possui (ownership + participacao) para :target_user_id
        # e entao apaga o registro — mesma logica de Admin::UsersController#realizar_exclusao.
        def destroy
          if @user == @current_api_user
            return render json: { error: "Não é possível excluir a própria conta via API" }, status: :unprocessable_content
          end

          target = User.find_by(id: params[:target_user_id])
          return render json: { error: "target_user_id inválido" }, status: :unprocessable_content unless target

          nome = @user.display_name
          Users::TransferAndDelete.call(source: @user, target: target)
          render json: { message: "#{nome} excluído(a), tudo transferido para #{target.display_name}" }
        rescue StandardError => e
          render json: { error: e.message.truncate(200) }, status: :unprocessable_content
        end

        private

        def set_user
          @user = User.find(params[:id])
        end

        def create_params
          params.require(:user).permit(:name, :email, :role, :area, :supervisor_id, :sankhya_record_id)
        end

        def update_params
          params.require(:user).permit(:role, :area, :supervisor_id, :active, :name, :sankhya_record_id)
        end

        def serialize(user, detailed: false)
          base = {
            id: user.id, name: user.name, email: user.email, role: user.role,
            area: user.area, active: user.active, supervisor_id: user.supervisor_id
          }
          return base unless detailed

          base.merge(
            created_at: user.created_at, sankhya_record_id: user.sankhya_record_id,
            demands_count: user.demands.count,
            tasks_assigned_count: ProjectTask.where(assignee_id: user.id).count
          )
        end
      end
    end
  end
end

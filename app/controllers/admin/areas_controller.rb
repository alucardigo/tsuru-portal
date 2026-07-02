# frozen_string_literal: true

module Admin
  # CRUD de áreas + atribuição de usuários a áreas.
  class AreasController < BaseController
    def index
      @areas = Area.order(:name)
      @sem_area = User.ativos.where(area: [ nil, "" ]).order(:name)
    end

    def create
      area = Area.new(name: params.require(:name).strip)
      if area.save
        redirect_to admin_areas_path, notice: "Área \"#{area.name}\" criada."
      else
        redirect_to admin_areas_path, alert: area.errors.full_messages.join(", ")
      end
    end

    def destroy
      area = Area.find(params[:id])
      afetados = User.where(area: area.name).count
      User.where(area: area.name).update_all(area: nil)
      area.destroy
      redirect_to admin_areas_path,
                  notice: "Área \"#{area.name}\" removida#{afetados.positive? ? " (#{afetados} usuário(s) ficaram sem área)" : ''}."
    end

    # PATCH /admin/areas/:id/assign_user (body: user_id)
    def assign_user
      area = Area.find(params[:id])
      user = User.find(params[:user_id])
      user.update!(area: area.name)
      redirect_to admin_areas_path, notice: "#{user.display_name} atribuído(a) à área #{area.name}."
    end

    # PATCH /admin/areas/:id/remove_user (body: user_id)
    def remove_user
      area = Area.find(params[:id])
      user = User.find(params[:user_id])
      user.update!(area: nil) if user.area == area.name
      redirect_to admin_areas_path, notice: "#{user.display_name} removido(a) da área."
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    module Admin
      class AreasController < BaseController
        before_action :set_area, only: %i[update destroy]

        def index
          render json: Area.order(:name).map { |a| { id: a.id, name: a.name } }
        end

        def create
          area = Area.new(area_params)
          if area.save
            render json: { id: area.id, name: area.name }, status: :created
          else
            render json: { error: area.errors.full_messages.join(", ") }, status: :unprocessable_content
          end
        end

        def update
          if @area.update(area_params)
            render json: { id: @area.id, name: @area.name }
          else
            render json: { error: @area.errors.full_messages.join(", ") }, status: :unprocessable_content
          end
        end

        # Mesmo comportamento da tela admin: destroy anula users.area (não apaga usuários).
        def destroy
          @area.destroy
          render json: { message: "Área removida" }
        end

        private

        def set_area
          @area = Area.find(params[:id])
        end

        def area_params
          params.require(:area).permit(:name)
        end
      end
    end
  end
end

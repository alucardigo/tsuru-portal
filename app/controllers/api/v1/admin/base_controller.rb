# frozen_string_literal: true

# API administrativa completa do Tsuru — pensada para agentes de codigo (Claude Code, etc)
# gerenciarem o portal remotamente com privilegios de admin. Mesma autenticacao por
# "Authorization: Bearer <api_token>" da Api::V1::BaseController, mas exige role admin:
# um token de usuario colaborador/gestor comum NUNCA passa daqui, mesmo que valido.
module Api
  module V1
    module Admin
      class BaseController < Api::V1::BaseController
        before_action :require_admin!

        private

        def require_admin!
          return if @current_api_user&.admin?

          render json: { error: "Requer papel admin" }, status: :forbidden
        end

        # Paginacao manual (o app usa Pagy pro controller-layer com views; aqui e API pura
        # ActionController::API, mais simples nao acoplar ao Pagy::Backend por enquanto).
        def paginate(scope)
          page = [ params[:page].presence&.to_i || 1, 1 ].max
          per  = [ params[:per_page].presence&.to_i || 30, 100 ].min
          scope.offset((page - 1) * per).limit(per)
        end
      end
    end
  end
end

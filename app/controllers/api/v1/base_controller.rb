# frozen_string_literal: true

# Bloco H — base da API REST usada por integrações externas (Power Automate, Zapier, n8n).
# Autenticação via "Authorization: Bearer <api_token>" (gerado em /users/edit).
module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_token!

      private

      def authenticate_token!
        token = request.headers["Authorization"].to_s.remove("Bearer ").strip
        @current_api_user = User.find_by(api_token: token) if token.present?
        render json: { error: "Token inválido ou ausente" }, status: :unauthorized unless @current_api_user
      end
    end
  end
end

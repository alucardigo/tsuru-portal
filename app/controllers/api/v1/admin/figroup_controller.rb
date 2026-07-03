# frozen_string_literal: true

require "base64"

module Api
  module V1
    module Admin
      # Endpoint máquina-a-máquina para o agente-guardião (headless) manter a
      # integração FI Group viva: ele captura o Bearer renovado do portal e o
      # entrega aqui, sem intervenção humana. Autenticado por api_token de admin.
      class FigroupController < BaseController
        # POST /api/v1/admin/figroup/refresh_token  { token: "<JWT>" }
        # Atualiza a FiGroupCredential ativa com o token novo. expires_at é
        # derivado do claim exp do próprio JWT (com margem de 60s).
        def refresh_token
          result = FiGroup::TokenIngest.call(params[:token], captured_by: @current_api_user)
          if result.ok
            cred = result.credential
            render json: { ok: true, expires_at: cred.expires_at, expires_in_sec: (cred.expires_at - Time.current).to_i }
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end

        # GET /api/v1/admin/figroup/status — o guardião consulta se precisa renovar.
        def status
          cred = FiGroupCredential.current
          render json: {
            present: cred.present?,
            active: cred&.active? || false,
            expires_at: cred&.expires_at,
            expires_in_sec: cred ? (cred.expires_at - Time.current).to_i : nil
          }
        end
      end
    end
  end
end

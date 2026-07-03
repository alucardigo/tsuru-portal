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
          token = params[:token].to_s.strip.sub(/\ABearer\s+/i, "")
          return render(json: { error: "token ausente" }, status: :unprocessable_entity) if token.blank?

          exp = jwt_exp(token)
          expires_at = exp ? Time.at(exp - 60) : Time.current + 55.minutes
          if expires_at <= Time.current
            return render(json: { error: "token já expirado (exp no passado)" }, status: :unprocessable_entity)
          end

          cred = FiGroupCredential.current
          if cred.nil?
            return render(json: { error: "sem credencial base — capture o token uma vez em /admin/figroup antes de automatizar" }, status: :unprocessable_entity)
          end

          cred.update!(token: token, expires_at: expires_at, captured_by: @current_api_user)
          render json: { ok: true, expires_at: cred.expires_at, expires_in_sec: (cred.expires_at - Time.current).to_i }
        rescue ActiveRecord::RecordInvalid => e
          render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
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

        private

        # Decodifica só o payload do JWT (sem validar assinatura) para ler o exp.
        def jwt_exp(token)
          payload = token.split(".")[1]
          return nil if payload.blank?

          padded = payload + ("=" * ((4 - (payload.length % 4)) % 4))
          JSON.parse(Base64.urlsafe_decode64(padded))["exp"]
        rescue StandardError
          nil
        end
      end
    end
  end
end

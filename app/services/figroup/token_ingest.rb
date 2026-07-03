# frozen_string_literal: true

require "base64"
require "json"

module FiGroup
  # Recebe um access_token (JWT) capturado do portal da FI e atualiza a
  # FiGroupCredential ativa. Usado tanto pelo bookmarklet (sessão web) quanto
  # pelo endpoint máquina-a-máquina do guardião. expires_at vem do claim exp
  # do próprio JWT (com margem de 60s), então a validade é sempre real.
  class TokenIngest
    Result = Struct.new(:ok, :credential, :error, keyword_init: true)

    def self.call(raw_token, captured_by: nil)
      token = raw_token.to_s.strip.sub(/\ABearer\s+/i, "")
      return Result.new(ok: false, error: "token ausente") if token.blank?

      exp = jwt_exp(token)
      expires_at = exp ? Time.at(exp - 60) : Time.current + 55.minutes
      return Result.new(ok: false, error: "token já expirado (exp no passado)") if expires_at <= Time.current

      cred = FiGroupCredential.current
      if cred.nil?
        return Result.new(ok: false, error: "sem credencial base — capture o token uma vez pelo formulário antes de usar o botão")
      end

      cred.update!(token: token, expires_at: expires_at, captured_by: captured_by)
      Result.new(ok: true, credential: cred)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(ok: false, error: e.record.errors.full_messages.join(", "))
    end

    # Decodifica só o payload do JWT (sem validar assinatura) para ler o exp.
    def self.jwt_exp(token)
      payload = token.split(".")[1]
      return nil if payload.blank?

      padded = payload + ("=" * ((4 - (payload.length % 4)) % 4))
      JSON.parse(Base64.urlsafe_decode64(padded))["exp"]
    rescue StandardError
      nil
    end
  end
end

# frozen_string_literal: true

module FiGroup
  # Levantado quando não há credencial ativa ou a API do LeidoBem responde 401
  # (token expirado/inválido — precisa recapturar o header Authorization no portal).
  # Em arquivo próprio para ser autoloadable pelo Zeitwerk independentemente do Client.
  class AuthError < StandardError; end
end

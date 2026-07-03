module Sankhya
  class Client
    # Fluxo OAuth 2.0 Client Credentials do Gateway Sankhya (novo; o antigo
    # login.sankhya.com.br/oauth/token foi descontinuado e responde 403).
    # Precisa: client_id + client_secret (Área do Desenvolvedor) + X-Token
    # (tela "Configurações Gateway" do Sankhya Om). Ver developer.sankhya.com.br.
    AUTH_URL = "https://api.sankhya.com.br/authenticate"
    CIRCUIT_NAME = "sankhya-api"

    def initialize
      @http = Faraday.new do |f|
        f.request :retry, max: 2, interval: 0.5,
                           retry_statuses: [ 429, 500, 502, 503, 504 ]
        f.response :raise_error
        f.adapter Faraday.default_adapter
      end
    end

    def circuit_breaker
      @circuit_breaker ||= Stoplight(CIRCUIT_NAME) { nil }
    end

    def token
      response = @http.post(AUTH_URL) do |req|
        req.headers["X-Token"] = credentials(:x_token)
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form(
          grant_type: "client_credentials",
          client_id: credentials(:client_id),
          client_secret: credentials(:client_secret)
        )
      end
      body = JSON.parse(response.body)
      body["access_token"] || body["bearerToken"]
    end

    def healthy?
      circuit_breaker.run { token.present? }
    rescue Stoplight::Error::RedLight, Faraday::Error
      false
    end

    private

    def credentials(key)
      Rails.application.credentials.dig(:sankhya, key) ||
        ENV.fetch("SANKHYA_#{key.to_s.upcase}", nil)
    end
  end
end

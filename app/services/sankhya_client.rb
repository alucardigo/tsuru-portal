class SankhyaClient
  TOKEN_URL = "https://login.sankhya.com.br/oauth/token"
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
    response = @http.post(TOKEN_URL) do |req|
      req.headers["Content-Type"] = "application/x-www-form-urlencoded"
      req.body = URI.encode_www_form(
        grant_type: "client_credentials",
        client_id: credentials(:client_id),
        client_secret: credentials(:client_secret)
      )
    end
    JSON.parse(response.body)["access_token"]
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

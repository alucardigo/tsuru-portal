class Rack::Attack
  # Safelist: never throttle localhost
  safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end

  # Login: 5 attempts per IP per 20 seconds
  throttle("login/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  # TOTP: 3 attempts per IP per 60 seconds
  throttle("totp/ip", limit: 3, period: 60.seconds) do |req|
    req.ip if req.path.include?("/users/two_factor") && req.post?
  end

  # Sankhya proxy: 10 requests per IP per 60 seconds
  throttle("sankhya/ip", limit: 10, period: 60.seconds) do |req|
    req.ip if req.path.include?("/sankhya")
  end

  self.throttled_responder = lambda do |_env|
    [ 429, { "Content-Type" => "application/json" },
      [ { error: "Muitas tentativas. Aguarde e tente novamente." }.to_json ] ]
  end
end

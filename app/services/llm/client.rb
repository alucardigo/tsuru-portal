# frozen_string_literal: true

require "net/http"
require "json"

module Llm
  # Cliente unificado de chat-completion — OpenAI, Anthropic, Gemini e
  # servidores locais OpenAI-compatíveis (Ollama, LM Studio, vLLM).
  # Uso: Llm::Client.chat(provider, "prompt", system: "instrução opcional")
  class Client
    Result = Struct.new(:ok, :content, :error, :latency_ms) do
      def success? = ok
    end

    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 60

    class << self
      def chat(provider, prompt, system: nil)
        t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        content =
          case provider.kind
          when "openai", "local" then openai_chat(provider, prompt, system)
          when "anthropic"       then anthropic_chat(provider, prompt, system)
          when "gemini"          then gemini_chat(provider, prompt, system)
          else raise ArgumentError, "kind não suportado: #{provider.kind}"
          end
        Result.new(true, content.to_s.strip, nil, elapsed_ms(t0))
      rescue StandardError => e
        Result.new(false, nil, "#{e.class}: #{e.message}".truncate(400), elapsed_ms(t0))
      end

      private

      def elapsed_ms(t0)
        ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000).round
      end

      def post_json(url, headers, payload)
        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")
        http.open_timeout = OPEN_TIMEOUT
        http.read_timeout = READ_TIMEOUT
        req = Net::HTTP::Post.new(uri.request_uri, { "Content-Type" => "application/json" }.merge(headers))
        req.body = payload.to_json
        res = http.request(req)
        body = begin
          JSON.parse(res.body)
        rescue StandardError
          { "raw" => res.body.to_s[0, 300] }
        end
        unless res.code.to_i.between?(200, 299)
          err = body.dig("error", "message") || body["error"] || body["raw"] || res.body.to_s[0, 200]
          raise "HTTP #{res.code} — #{err}"
        end
        body
      end

      # OpenAI e locais OpenAI-compatíveis (mesmo contrato /v1/chat/completions)
      def openai_chat(p, prompt, system)
        base = p.base_url.presence || "https://api.openai.com"
        messages = []
        messages << { role: "system", content: system } if system.present?
        messages << { role: "user", content: prompt }
        headers = p.api_key.present? ? { "Authorization" => "Bearer #{p.api_key}" } : {}
        body = post_json("#{base.chomp('/')}/v1/chat/completions", headers,
                         { model: p.model, messages: messages })
        body.dig("choices", 0, "message", "content")
      end

      def anthropic_chat(p, prompt, system)
        base = p.base_url.presence || "https://api.anthropic.com"
        payload = { model: p.model, max_tokens: 1024,
                    messages: [ { role: "user", content: prompt } ] }
        payload[:system] = system if system.present?
        body = post_json("#{base.chomp('/')}/v1/messages",
                         { "x-api-key" => p.api_key.to_s, "anthropic-version" => "2023-06-01" },
                         payload)
        Array(body["content"]).filter_map { |c| c["text"] }.join
      end

      def gemini_chat(p, prompt, system)
        base = p.base_url.presence || "https://generativelanguage.googleapis.com"
        url = "#{base.chomp('/')}/v1beta/models/#{p.model}:generateContent?key=#{p.api_key}"
        payload = { contents: [ { role: "user", parts: [ { text: prompt } ] } ] }
        payload[:systemInstruction] = { parts: [ { text: system } ] } if system.present?
        body = post_json(url, {}, payload)
        body.dig("candidates", 0, "content", "parts", 0, "text")
      end
    end
  end
end

# frozen_string_literal: true

# Provedor de LLM configurável pelo admin. A API key fica criptografada no banco
# (Active Record encryption — mesmas chaves do 2FA já configuradas em prod).
class LlmProvider < ApplicationRecord
  KINDS = %w[openai anthropic gemini local].freeze
  KIND_LABELS = {
    "openai"    => "OpenAI (GPT)",
    "anthropic" => "Anthropic (Claude)",
    "gemini"    => "Google (Gemini)",
    "local"     => "Local / OpenAI-compatível (Ollama, LM Studio, vLLM…)"
  }.freeze
  DEFAULT_MODELS = {
    "openai"    => "gpt-4o-mini",
    "anthropic" => "claude-sonnet-4-5",
    "gemini"    => "gemini-2.0-flash",
    "local"     => "llama3"
  }.freeze

  encrypts :api_key

  validates :name,  presence: true, length: { maximum: 80 }
  validates :kind,  inclusion: { in: KINDS }
  validates :model, presence: true
  validates :base_url, presence: { message: "é obrigatória para provedor local" }, if: -> { kind == "local" }
  validates :api_key, presence: true, unless: -> { kind == "local" }

  scope :enabled, -> { where(enabled: true) }

  def kind_label = KIND_LABELS[kind] || kind

  def masked_key
    return "—" if api_key.blank?
    key = api_key.to_s
    key.length > 10 ? "#{key[0, 5]}…#{key[-4, 4]}" : "•••"
  end
end

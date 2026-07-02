# frozen_string_literal: true

module Admin
  class LlmProvidersController < BaseController
    before_action :set_provider, only: %i[update destroy test]

    def index
      @providers = LlmProvider.order(:name)
      @provider  = LlmProvider.new(kind: "openai")
    end

    def create
      @provider = LlmProvider.new(provider_params)
      @provider.model = LlmProvider::DEFAULT_MODELS[@provider.kind] if @provider.model.blank?
      if @provider.save
        redirect_to admin_llm_providers_path, notice: "Provedor \"#{@provider.name}\" criado. Use Testar para validar a conexão."
      else
        redirect_to admin_llm_providers_path, alert: @provider.errors.full_messages.join(", ")
      end
    end

    # Toggle enabled ou update de campos (form inline)
    def update
      attrs = provider_params
      attrs = attrs.except(:api_key) if attrs[:api_key].blank?  # não sobrescrever key com vazio
      if @provider.update(attrs)
        redirect_to admin_llm_providers_path, notice: "Provedor atualizado."
      else
        redirect_to admin_llm_providers_path, alert: @provider.errors.full_messages.join(", ")
      end
    end

    def destroy
      @provider.destroy
      redirect_to admin_llm_providers_path, notice: "Provedor removido."
    end

    # POST /admin/llm_providers/:id/test — chamada real, mostra resposta/erro + latência
    def test
      result = Llm::Client.chat(@provider, "Responda somente com a palavra: OK")
      if result.success?
        redirect_to admin_llm_providers_path,
                    notice: "✅ #{@provider.name} respondeu em #{result.latency_ms}ms: \"#{result.content.truncate(80)}\""
      else
        redirect_to admin_llm_providers_path,
                    alert: "❌ #{@provider.name} falhou (#{result.latency_ms}ms): #{result.error}"
      end
    end

    private

    def set_provider
      @provider = LlmProvider.find(params[:id])
    end

    def provider_params
      params.require(:llm_provider).permit(:name, :kind, :model, :base_url, :api_key, :enabled)
    end
  end
end

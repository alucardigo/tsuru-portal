# frozen_string_literal: true

# Bloco H — permite ao usuário logado gerar/renovar o token usado por integrações externas
# (Power Automate, Zapier, n8n) para autenticar chamadas na API REST do Tsuru.
class ApiTokensController < ApplicationController
  def regenerate
    current_user.regenerate_api_token!
    redirect_to edit_user_registration_path, notice: "Novo token de API gerado."
  end
end

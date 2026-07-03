require "rails_helper"

RSpec.describe "Atualizações", type: :request do
  describe "acesso" do
    it "bloqueia colaborador" do
      sign_in create(:user)
      get atualizacoes_path
      expect(response).to redirect_to(root_path)
    end

    it "permite gestor" do
      sign_in create(:user, :gestor)
      get atualizacoes_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /atualizacoes" do
    before { sign_in create(:user, :admin) }

    it "mostra demandas em andamento" do
      em_andamento = create(:demand, :em_triagem)
      get atualizacoes_path
      expect(response.body).to include(em_andamento.codigo_display)
    end

    it "mostra demandas em standby" do
      em_standby = create(:demand, aasm_state: "awaiting_requester")
      get atualizacoes_path
      expect(response.body).to include(em_standby.codigo_display)
    end

    it "não estoura quando não há nenhuma demanda" do
      get atualizacoes_path
      expect(response).to have_http_status(:ok)
    end

    it "mostra atividade recente combinando transições e comentários" do
      demand = create(:demand, aasm_state: "rascunho")
      demand.submeter!
      create(:comment, demand: demand, body: "comentário de teste")

      get atualizacoes_path

      expect(response.body).to include(demand.codigo_display)
    end
  end
end

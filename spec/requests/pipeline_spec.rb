require "rails_helper"

RSpec.describe "GET /pipeline", type: :request do
  let(:analista) { create(:user, role: "analista_pdi") }
  let(:colaborador) { create(:user, role: "colaborador") }

  describe "acesso" do
    it "permite gestor_or_above" do
      sign_in analista
      get pipeline_path
      expect(response).to have_http_status(:ok)
    end

    it "bloqueia colaborador" do
      sign_in colaborador
      get pipeline_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "agrupamento por coluna" do
    before do
      sign_in analista
      create(:demand, aasm_state: "submetida", title: "Triagem A")
      create(:demand, aasm_state: "em_triagem", title: "Triagem B")
      create(:demand, aasm_state: "n2_em_andamento", title: "N2 C")
      create(:demand, aasm_state: "elegivel", title: "Elegível D")
      create(:demand, aasm_state: "concluida", title: "Concluida E")
      create(:demand, aasm_state: "n1_reprovada", title: "Rejeitada F")
    end

    it "exibe cada coluna com seus cards" do
      get pipeline_path
      body = response.body
      expect(body).to include("Triagem N1")
      expect(body).to include("Avaliação N2")
      expect(body).to include("Decisão")
      expect(body).to include("PD&amp;I executando")
      expect(body).to include("Concluído")
      expect(body).to include("Não elegíveis")
    end
  end
end

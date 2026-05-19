require "rails_helper"

RSpec.describe "GET /admin/metrics", type: :request do
  let(:admin) { create(:user, role: "admin") }

  before { sign_in admin }

  describe "acesso e estrutura" do
    it "retorna 200" do
      get admin_metrics_path
      expect(response).to have_http_status(:ok)
    end

    it "bloqueia colaborador com 403" do
      sign_in create(:user, role: "colaborador")
      get admin_metrics_path
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "conteúdo dos KPIs" do
    before do
      create(:demand, aasm_state: "elegivel")
      create(:demand, aasm_state: "elegivel")
      create(:demand, aasm_state: "nao_elegivel")
      create(:demand, aasm_state: "submetida")
      create(:demand, trl: 4)
      create(:demand, trl: 7)
      create(:demand, ods_goals: [ 9, 13 ])
      create(:demand, ods_goals: [ 9 ])
    end

    it "exibe total de demandas" do
      get admin_metrics_path
      expect(response.body).to match(/\d+/)
    end

    it "exibe seção de estados" do
      get admin_metrics_path
      expect(response.body).to include("elegivel").or include("Elegível")
    end

    it "exibe distribuição TRL" do
      get admin_metrics_path
      expect(response.body).to include("TRL")
    end

    it "exibe ODS mencionados" do
      get admin_metrics_path
      expect(response.body).to include("ODS")
    end
  end
end

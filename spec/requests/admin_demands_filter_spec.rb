require "rails_helper"

RSpec.describe "Admin demands filtros avançados", type: :request do
  let(:admin) { create(:user, role: "admin") }

  before { sign_in admin }

  describe "busca por título" do
    before do
      create(:demand, title: "Projeto Alpha machine learning")
      create(:demand, title: "Projeto Beta automação")
    end

    it "retorna apenas demandas que casam com o termo" do
      get admin_demands_path, params: { q: "Alpha" }
      expect(response.body).to include("Alpha")
      expect(response.body).not_to include("Beta automação")
    end

    it "busca é case-insensitive" do
      get admin_demands_path, params: { q: "alpha" }
      expect(response.body).to include("Alpha")
    end
  end

  describe "filtro por TRL" do
    before do
      create(:demand, title: "TRL4 demand", trl: 4)
      create(:demand, title: "TRL7 demand", trl: 7)
    end

    it "retorna apenas demandas com o TRL especificado" do
      get admin_demands_path, params: { trl: 4 }
      expect(response.body).to include("TRL4")
      expect(response.body).not_to include("TRL7")
    end
  end

  describe "filtro por intervalo de datas" do
    let!(:old_demand) { create(:demand, title: "Demanda Antiga", created_at: 2.months.ago) }
    let!(:new_demand) { create(:demand, title: "Demanda Nova", created_at: Time.current) }

    it "filtra por data_ini" do
      get admin_demands_path, params: { data_ini: 1.week.ago.to_date.iso8601 }
      expect(response.body).to include("Demanda Nova")
      expect(response.body).not_to include("Demanda Antiga")
    end

    it "filtra por data_fim" do
      get admin_demands_path, params: { data_fim: 1.month.ago.to_date.iso8601 }
      expect(response.body).to include("Demanda Antiga")
      expect(response.body).not_to include("Demanda Nova")
    end
  end

  describe "combinação de filtros" do
    before do
      create(:demand, title: "Match total", trl: 5, aasm_state: "elegivel")
      create(:demand, title: "Errado estado", trl: 5, aasm_state: "rascunho")
      create(:demand, title: "Errado TRL", trl: 3, aasm_state: "elegivel")
    end

    it "aplica estado + TRL juntos" do
      get admin_demands_path, params: { estado: "elegivel", trl: 5 }
      expect(response.body).to include("Match total")
      expect(response.body).not_to include("Errado estado")
      expect(response.body).not_to include("Errado TRL")
    end
  end
end

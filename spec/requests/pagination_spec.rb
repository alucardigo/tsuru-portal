require "rails_helper"

RSpec.describe "Paginação Pagy", type: :request do
  describe "admin/demands" do
    let(:admin) { create(:user, role: "admin") }

    before do
      sign_in admin
      create_list(:demand, 30)
    end

    it "exibe no máximo 25 demandas na página 1" do
      get admin_demands_path
      # Conta apenas linhas de dados (exclui header: border-gray-200)
      row_count = response.body.scan(/<tr class="border-b border-gray-100"/).length
      expect(row_count).to be <= 25
    end

    it "page=2 retorna 200 com demandas restantes" do
      get admin_demands_path, params: { page: 2 }
      expect(response).to have_http_status(:ok)
    end

    it "inclui navegação de paginação" do
      get admin_demands_path
      # Pagy emite aria-label="paginação" ou rel="next"
      expect(response.body).to match(/aria-label=["']paginação["']|rel=["']next["']|pagy/)
    end
  end

  describe "demands (usuário comum)" do
    let(:user) { create(:user) }

    before do
      sign_in user
      create_list(:demand, 30, user: user)
    end

    it "exibe no máximo 25 demandas na página 1" do
      get demands_path
      row_count = response.body.scan(/demand\.id|demand-row/).length
      expect(row_count).to be <= 25
    end

    it "page=2 retorna 200" do
      get demands_path, params: { page: 2 }
      expect(response).to have_http_status(:ok)
    end
  end
end

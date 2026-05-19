require "rails_helper"

RSpec.describe "Admin Exports Lei do Bem", type: :request do
  let(:admin)       { create(:user, :admin) }
  let(:colaborador) { create(:user) }

  before do
    create(:demand, :elegivel_state, user: colaborador,
           title: "Otimização latência PostgreSQL",
           trl: 5, ods_goals: [ 9 ])
    sign_in admin
  end

  describe "GET /admin/demands.xlsx" do
    it "retorna 200" do
      get admin_demands_path(format: :xlsx)
      expect(response).to have_http_status(:ok)
    end

    it "retorna content-type xlsx" do
      get admin_demands_path(format: :xlsx)
      expect(response.content_type).to include("spreadsheetml")
    end

    it "aceita filtro por estado" do
      get admin_demands_path(format: :xlsx, estado: "elegivel")
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/demands.docx" do
    it "retorna 200" do
      get admin_demands_path(format: :docx)
      expect(response).to have_http_status(:ok)
    end

    it "retorna content-type docx" do
      get admin_demands_path(format: :docx)
      expect(response.content_type).to include("wordprocessingml")
    end
  end
end

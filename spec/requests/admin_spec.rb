require "rails_helper"

RSpec.describe "Admin Panel", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:gestor) { create(:user, :gestor) }
  let(:colaborador) { create(:user) }

  describe "GET /admin/users" do
    context "when admin" do
      before { sign_in admin }

      it "retorna 200" do
        get admin_users_path
        expect(response).to have_http_status(:ok)
      end

      it "lista email do gestor" do
        gestor
        get admin_users_path
        expect(response.body).to include(gestor.email)
      end

      it "lista email do colaborador" do
        colaborador
        get admin_users_path
        expect(response.body).to include(colaborador.email)
      end
    end

    context "when não admin" do
      before { sign_in gestor }

      it "retorna forbidden" do
        get admin_users_path
        expect(response).to have_http_status(:forbidden).or redirect_to(root_path)
      end
    end
  end

  describe "PATCH /admin/users/:id" do
    before { sign_in admin }

    it "altera role do usuário" do
      patch admin_user_path(colaborador), params: { user: { role: "gestor" } }
      expect(colaborador.reload).to be_gestor
    end

    it "redireciona para lista após update" do
      patch admin_user_path(colaborador), params: { user: { role: "gestor" } }
      expect(response).to redirect_to(admin_users_path)
    end
  end

  describe "GET /admin/demands" do
    before { sign_in admin }

    it "retorna 200 com todas as demandas" do
      create(:demand, user: colaborador)
      get admin_demands_path
      expect(response).to have_http_status(:ok)
    end

    it "aceita filtro por estado" do
      create(:demand, :submetida, user: colaborador)
      get admin_demands_path, params: { estado: "submetida" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/demands.csv" do
    before { sign_in admin }

    it "exporta CSV de demandas elegíveis" do
      create(:demand, :elegivel_state, user: colaborador)
      get admin_demands_path(format: :csv, estado: "elegivel")
      expect(response.content_type).to include("text/csv")
    end
  end
end

require "rails_helper"

RSpec.describe "Api::V1::Admin::Users", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:headers) { { "Authorization" => "Bearer #{admin.ensure_api_token!}" } }

  describe "auth" do
    it "rejeita sem token" do
      get "/api/v1/admin/users"
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejeita token de usuario nao-admin" do
      colaborador = create(:user)
      get "/api/v1/admin/users", headers: { "Authorization" => "Bearer #{colaborador.ensure_api_token!}" }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/admin/users" do
    it "lista usuarios e aceita filtro de busca" do
      create(:user, name: "Zeca Alvo")
      create(:user, name: "Outra Pessoa")

      get "/api/v1/admin/users", params: { q: "Zeca" }, headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.map { |u| u["name"] }).to eq([ "Zeca Alvo" ])
    end
  end

  describe "GET /api/v1/admin/users/:id" do
    it "retorna detalhes de um usuario" do
      user = create(:user)
      get "/api/v1/admin/users/#{user.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(user.id)
    end
  end

  describe "POST /api/v1/admin/users" do
    it "cria usuario" do
      post "/api/v1/admin/users",
           params: { user: { name: "Novo", email: "novo@bellube.com.br", role: "colaborador" } },
           headers: headers
      expect(response).to have_http_status(:created)
      expect(User.find_by(email: "novo@bellube.com.br")).to be_present
    end
  end

  describe "PATCH /api/v1/admin/users/:id" do
    it "atualiza role e area" do
      user = create(:user)
      patch "/api/v1/admin/users/#{user.id}",
            params: { user: { role: "gestor", area: "TI / Sistemas" } },
            headers: headers
      expect(response).to have_http_status(:ok)
      expect(user.reload.role).to eq("gestor")
    end
  end

  describe "DELETE /api/v1/admin/users/:id" do
    it "transfere ownership e exclui" do
      source = create(:user)
      target = create(:user)
      create(:demand, user: source)

      delete "/api/v1/admin/users/#{source.id}", params: { target_user_id: target.id }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(User.exists?(source.id)).to be false
      expect(target.demands.count).to eq(1)
    end

    it "rejeita exclusao sem target_user_id" do
      source = create(:user)
      delete "/api/v1/admin/users/#{source.id}", headers: headers
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end

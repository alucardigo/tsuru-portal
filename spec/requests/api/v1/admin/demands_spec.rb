require "rails_helper"

RSpec.describe "Api::V1::Admin::Demands", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:headers) { { "Authorization" => "Bearer #{admin.ensure_api_token!}" } }

  describe "GET /api/v1/admin/demands" do
    it "lista e filtra por estado" do
      create(:demand, aasm_state: "rascunho")
      create(:demand, :submetida)

      get "/api/v1/admin/demands", params: { state: "submetida" }, headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.size).to eq(1)
      expect(body.first["state"]).to eq("submetida")
    end
  end

  describe "POST /api/v1/admin/demands" do
    it "cria demanda em rascunho" do
      post "/api/v1/admin/demands",
           params: { demand: { title: "Nova sugestão", description: "Descrição válida", area_impactada: "TI / Sistemas" } },
           headers: headers
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["state"]).to eq("rascunho")
    end
  end

  describe "POST /api/v1/admin/demands/:id/transition" do
    it "dispara evento valido" do
      demand = create(:demand, aasm_state: "rascunho")
      post "/api/v1/admin/demands/#{demand.id}/transition", params: { event: "submeter" }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(demand.reload.aasm_state).to eq("submetida")
    end

    it "rejeita evento invalido" do
      demand = create(:demand, aasm_state: "rascunho")
      post "/api/v1/admin/demands/#{demand.id}/transition", params: { event: "voar" }, headers: headers
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejeita transicao ilegal para o estado atual" do
      demand = create(:demand, aasm_state: "rascunho")
      post "/api/v1/admin/demands/#{demand.id}/transition", params: { event: "aprovar_n1" }, headers: headers
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /api/v1/admin/demands/:id/comments" do
    it "cria comentario" do
      demand = create(:demand)
      post "/api/v1/admin/demands/#{demand.id}/comments", params: { body: "Comentário via API" }, headers: headers
      expect(response).to have_http_status(:created)
      expect(demand.comments.count).to eq(1)
    end
  end
end

require "rails_helper"

RSpec.describe "Api::V1::Admin::Areas", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:headers) { { "Authorization" => "Bearer #{admin.ensure_api_token!}" } }

  it "cria, lista e remove uma area" do
    post "/api/v1/admin/areas", params: { area: { name: "Nova Área" } }, headers: headers
    expect(response).to have_http_status(:created)
    id = JSON.parse(response.body)["id"]

    get "/api/v1/admin/areas", headers: headers
    expect(JSON.parse(response.body).map { |a| a["name"] }).to include("Nova Área")

    delete "/api/v1/admin/areas/#{id}", headers: headers
    expect(response).to have_http_status(:ok)
    expect(Area.exists?(id)).to be false
  end
end

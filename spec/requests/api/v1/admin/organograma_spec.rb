require "rails_helper"

RSpec.describe "Api::V1::Admin::Organograma", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:headers) { { "Authorization" => "Bearer #{admin.ensure_api_token!}" } }

  it "retorna a arvore com diretoria e subordinados" do
    diretor = create(:user, :board)
    gestor = create(:user, :gestor, supervisor_id: nil)
    create(:user, supervisor_id: gestor.id)

    get "/api/v1/admin/organograma", headers: headers

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["diretoria"].map { |u| u["id"] }).to include(diretor.id)
    gestor_node = body["hierarquia"].find { |u| u["id"] == gestor.id }
    expect(gestor_node["subordinados"].size).to eq(1)
  end
end

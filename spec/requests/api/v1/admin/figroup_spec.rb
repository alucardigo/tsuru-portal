require "rails_helper"
require "base64"

RSpec.describe "Api::V1::Admin::Figroup", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:headers) { { "Authorization" => "Bearer #{admin.ensure_api_token!}" } }

  # JWT sintético: só o payload importa (o endpoint lê exp sem validar assinatura).
  def fake_jwt(exp)
    payload = Base64.urlsafe_encode64({ exp: exp }.to_json).delete("=")
    "aaa.#{payload}.bbb"
  end

  let!(:cred) do
    FiGroupCredential.create!(token: "antigo", expires_at: 1.minute.ago, service_ids: { "2026" => "sid" })
  end

  it "renova a credencial com expires_at derivado do exp do JWT" do
    exp = 1.hour.from_now.to_i
    post "/api/v1/admin/figroup/refresh_token", params: { token: fake_jwt(exp) }, headers: headers

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["ok"]).to be(true)
    cred.reload
    expect(cred.active?).to be(true)
    expect(cred.expires_at.to_i).to be_within(2).of(exp - 60)
  end

  it "rejeita token já expirado" do
    post "/api/v1/admin/figroup/refresh_token", params: { token: fake_jwt(1.hour.ago.to_i) }, headers: headers
    expect(response).to have_http_status(:unprocessable_entity)
    expect(cred.reload.active?).to be(false)
  end

  it "rejeita quando falta o token" do
    post "/api/v1/admin/figroup/refresh_token", params: {}, headers: headers
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "exige autenticação de admin" do
    post "/api/v1/admin/figroup/refresh_token", params: { token: fake_jwt(1.hour.from_now.to_i) }
    expect(response).to have_http_status(:unauthorized)
  end

  it "status informa a validade atual" do
    get "/api/v1/admin/figroup/status", headers: headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to include("present", "active", "expires_in_sec")
  end
end

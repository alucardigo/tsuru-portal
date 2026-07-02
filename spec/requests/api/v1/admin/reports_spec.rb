require "rails_helper"

RSpec.describe "Api::V1::Admin::Reports", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:headers) { { "Authorization" => "Bearer #{admin.ensure_api_token!}" } }

  # Sem LlmProvider habilitado no ambiente de teste, o gerador falha graciosamente —
  # é o comportamento documentado de Ai::ReportGenerator, cobrimos o contrato de erro.
  it "retorna erro claro quando nao ha provedor de IA habilitado" do
    demand = create(:demand)
    post "/api/v1/admin/reports/demand/#{demand.id}", headers: headers
    expect(response).to have_http_status(:unprocessable_content)
    expect(JSON.parse(response.body)["error"]).to include("Nenhum provedor de IA habilitado")
  end
end

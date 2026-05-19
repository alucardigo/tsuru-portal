require "rails_helper"

RSpec.describe "GET /admin/demands/:id/relatorio_n3", type: :request do
  let(:admin) { create(:user, role: "admin") }
  let(:demand) do
    create(:demand,
           title: "IA para triagem de patentes",
           trl: 5,
           ods_goals: [ 9, 17 ],
           aasm_state: "elegivel",
           parecer_tecnico: "Projeto demonstra inovação real com barreira técnica documentada.")
  end

  before { sign_in admin }

  it "retorna 200 com Content-Type application/pdf" do
    get relatorio_n3_admin_demand_path(demand, format: :pdf)
    expect(response).to have_http_status(:ok)
    expect(response.content_type).to include("application/pdf")
  end

  it "Content-Disposition sugere nome de arquivo" do
    get relatorio_n3_admin_demand_path(demand, format: :pdf)
    expect(response.headers["Content-Disposition"]).to include("relatorio_n3")
  end

  it "bloqueia colaborador com 403" do
    sign_in create(:user, role: "colaborador")
    get relatorio_n3_admin_demand_path(demand, format: :pdf)
    expect(response).to have_http_status(:forbidden)
  end
end

require "rails_helper"

RSpec.describe "GET /admin/demands/:id/sankhya", type: :request do
  let(:admin) { create(:user, role: "admin") }
  let(:demand) { create(:demand) }

  before { sign_in admin }

  context "quando o codparc é fornecido" do
    before do
      allow_any_instance_of(SankhyaService).to receive(:notas_fiscais)
        .with(codparc: "123")
        .and_return([
          { "f" => [{ "$" => "42", "_" => "NUMNOTA" }, { "$" => "5000.00", "_" => "VLRNOTA" }] }
        ])
    end

    it "retorna 200 e exibe os dados Sankhya" do
      get sankhya_admin_demand_path(demand), params: { codparc: "123" }
      expect(response).to have_http_status(:ok)
    end

    it "exibe número da nota fiscal" do
      get sankhya_admin_demand_path(demand), params: { codparc: "123" }
      expect(response.body).to include("Notas Fiscais")
    end
  end

  context "quando o codparc não é fornecido" do
    it "exibe formulário solicitando codparc" do
      get sankhya_admin_demand_path(demand)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("codparc")
    end
  end

  context "quando o SankhyaService falha" do
    before do
      allow_any_instance_of(SankhyaService).to receive(:notas_fiscais)
        .and_raise(Faraday::Error.new("connection refused"))
    end

    it "redireciona com alerta de erro" do
      get sankhya_admin_demand_path(demand), params: { codparc: "999" }
      expect(response).to redirect_to(admin_demands_path)
      expect(flash[:alert]).to be_present
    end
  end

  context "quando usuário não é admin" do
    let(:common_user) { create(:user, role: "colaborador") }

    before { sign_in common_user }

    it "retorna 403 Forbidden" do
      get sankhya_admin_demand_path(demand)
      expect(response).to have_http_status(:forbidden)
    end
  end
end

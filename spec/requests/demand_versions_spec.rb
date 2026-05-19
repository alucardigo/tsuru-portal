require "rails_helper"

RSpec.describe "Demand Versions (Audit Trail)", type: :request do
  let(:gestor)      { create(:user, :gestor) }
  let(:colaborador) { create(:user) }
  let!(:demand)     { create(:demand, :submetida, user: colaborador) }

  describe "GET /demands/:id/versions" do
    context "when gestor" do
      before { sign_in gestor }

      it "retorna 200" do
        get versions_demand_path(demand)
        expect(response).to have_http_status(:ok)
      end

      it "lista versões da demanda" do
        demand.update!(title: "Novo título atualizado")
        get versions_demand_path(demand)
        expect(response.body).to include("title")
      end

      it "mostra whodunnit" do
        PaperTrail.request.whodunnit = gestor.id.to_s
        demand.update!(title: "Alterado pelo gestor")
        get versions_demand_path(demand)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when colaborador dono" do
      before { sign_in colaborador }

      it "retorna 200" do
        get versions_demand_path(demand)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when outro colaborador" do
      let(:outro) { create(:user) }

      before { sign_in outro }

      it "redireciona ou retorna forbidden" do
        get versions_demand_path(demand)
        expect(response).to redirect_to(demands_path).or have_http_status(:forbidden)
      end
    end
  end
end

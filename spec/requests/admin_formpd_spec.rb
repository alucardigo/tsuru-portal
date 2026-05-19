require "rails_helper"

RSpec.describe "Admin FORMP&D Export", type: :request do
  let(:admin)       { create(:user, :admin) }
  let(:colaborador) { create(:user) }
  let!(:demand)     { create(:demand, :elegivel_state, user: colaborador, trl: 6, ods_goals: [ 9 ]) }

  describe "GET /admin/demands/:id/formpd.json" do
    context "when admin" do
      before { sign_in admin }

      it "returns 200" do
        get formpd_admin_demand_path(demand, format: :json)
        expect(response).to have_http_status(:ok)
      end

      it "returns JSON with schema_versao" do
        get formpd_admin_demand_path(demand, format: :json)
        body = JSON.parse(response.body)
        expect(body["schema_versao"]).to eq("FORMPD-2025")
      end

      it "returns JSON with trl" do
        get formpd_admin_demand_path(demand, format: :json)
        body = JSON.parse(response.body)
        expect(body["trl"]).to eq(6)
      end

      it "returns correct content-type" do
        get formpd_admin_demand_path(demand, format: :json)
        expect(response.content_type).to include("application/json")
      end
    end

    context "when não admin" do
      before { sign_in colaborador }

      it "returns forbidden" do
        get formpd_admin_demand_path(demand, format: :json)
        expect(response).to have_http_status(:forbidden).or redirect_to(root_path)
      end
    end
  end
end

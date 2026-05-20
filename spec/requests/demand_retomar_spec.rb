require "rails_helper"

RSpec.describe "PATCH /demands/:id/retomar", type: :request do
  let(:owner) { create(:user, role: "colaborador") }
  let(:demand) { create(:demand, user: owner, aasm_state: "awaiting_requester") }

  before { sign_in owner }

  it "autor reenvia demanda devolvida (awaiting_requester → submetida)" do
    expect {
      patch retomar_demand_path(demand)
    }.to change { demand.reload.aasm_state }.from("awaiting_requester").to("submetida")
  end

  it "não permite reenviar quando não está awaiting_requester" do
    demand.update_columns(aasm_state: "rascunho")
    patch retomar_demand_path(demand)
    expect(demand.reload.aasm_state).to eq("rascunho")
  end
end

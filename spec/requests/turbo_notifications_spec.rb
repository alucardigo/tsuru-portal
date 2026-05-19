require "rails_helper"

RSpec.describe "Turbo broadcast ao mudar estado demand", type: :request do
  let(:admin) { create(:user, role: "admin") }
  let(:owner) { create(:user, role: "colaborador") }
  let(:demand) { create(:demand, user: owner, aasm_state: "submetida") }

  before { sign_in admin }

  it "chama broadcast Turbo ao iniciar triagem" do
    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_later_to).at_least(:once)
    patch iniciar_triagem_demand_path(demand)
  end

  it "broadcast usa o canal do dono da demand" do
    canal_capturado = nil
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_later_to) do |canal, **|
      canal_capturado = canal
    end
    patch iniciar_triagem_demand_path(demand)
    expect(canal_capturado.to_s).to include(owner.id.to_s)
  end

  it "estado muda para em_triagem após o patch" do
    patch iniciar_triagem_demand_path(demand)
    expect(demand.reload.aasm_state).to eq("em_triagem")
  end
end

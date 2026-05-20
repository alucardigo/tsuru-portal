require "rails_helper"

RSpec.describe "Demand state machine wires DemandTransition", type: :model do
  let(:user) { create(:user, role: "colaborador") }
  let(:actor) { create(:user, role: "gestor") }
  let(:demand) { create(:demand, user: user) }

  before { Current.user = nil }
  after  { Current.user = nil }

  describe "after_transition callback" do
    it "cria DemandTransition quando submeter dispara" do
      Current.user = actor

      expect {
        demand.submeter
        demand.save!
      }.to change(DemandTransition, :count).by(1)

      t = demand.transitions.last
      expect(t.from_state).to eq("rascunho")
      expect(t.to_state).to eq("submetida")
      expect(t.event).to eq("submeter")
      expect(t.actor).to eq(actor)
    end

    it "actor pode ser nil quando Current.user não está setado (job em background)" do
      Current.user = nil

      expect {
        demand.submeter
        demand.save!
      }.to change(DemandTransition, :count).by(1)

      expect(demand.transitions.last.actor).to be_nil
    end

    it "encadeia múltiplas transições" do
      Current.user = actor
      demand.submeter
      demand.save!
      demand.iniciar_triagem
      demand.save!

      expect(demand.transitions.pluck(:event)).to eq(%w[submeter iniciar_triagem])
    end
  end

  describe "append-only enforcement (re-check)" do
    let!(:t) do
      Current.user = actor
      demand.submeter
      demand.save!
      demand.transitions.last
    end

    it "PG bloqueia UPDATE em transition" do
      expect {
        ActiveRecord::Base.connection.execute(
          "UPDATE demand_transitions SET to_state = 'hack' WHERE id = #{t.id}"
        )
      }.to raise_error(ActiveRecord::StatementInvalid, /append-only/i)
    end
  end
end

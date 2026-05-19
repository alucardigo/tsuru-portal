require "rails_helper"

RSpec.describe DemandTransition, type: :model do
  let(:demand) { create(:demand) }

  describe "append-only enforcement" do
    let!(:transition) do
      DemandTransition.create!(
        demand: demand, from_state: "rascunho", to_state: "submetida",
        event: "submeter", created_at: Time.current
      )
    end

    it "permite criar" do
      expect(transition).to be_persisted
    end

    it "PG bloqueia UPDATE via trigger" do
      expect {
        ActiveRecord::Base.connection.execute(
          "UPDATE demand_transitions SET to_state = 'hack' WHERE id = #{transition.id}"
        )
      }.to raise_error(ActiveRecord::StatementInvalid, /append-only/i)
    end

    it "PG bloqueia DELETE via trigger" do
      expect {
        ActiveRecord::Base.connection.execute(
          "DELETE FROM demand_transitions WHERE id = #{transition.id}"
        )
      }.to raise_error(ActiveRecord::StatementInvalid, /append-only/i)
    end

    it "AR readonly? true para registros persistidos" do
      expect(transition.readonly?).to be true
    end
  end
end

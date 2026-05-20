require "rails_helper"

RSpec.describe BoardDecision, type: :model do
  let(:demand) { create(:demand) }
  let(:decider) { create(:user, role: "board") }

  describe "validações" do
    let(:base_attrs) do
      { demand: demand, decider: decider, outcome: "approved",
        justification: "a" * 110 }
    end

    it "aceita registro válido" do
      expect(BoardDecision.new(base_attrs)).to be_valid
    end

    it "rejeita outcome fora da lista" do
      expect(BoardDecision.new(base_attrs.merge(outcome: "maybe"))).not_to be_valid
    end

    it "rejeita justificativa curta" do
      expect(BoardDecision.new(base_attrs.merge(justification: "curto"))).not_to be_valid
    end

    it "aceita os 3 outcomes válidos" do
      %w[approved rejected deferred].each do |o|
        expect(BoardDecision.new(base_attrs.merge(outcome: o))).to be_valid
      end
    end
  end

  describe "append-only" do
    let!(:bd) { BoardDecision.create!(demand: demand, decider: decider, outcome: "approved", justification: "x" * 120) }

    it "readonly após persistir" do
      expect(bd.readonly?).to be true
    end

    it "destroy é bloqueado" do
      expect { bd.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord, /append-only/)
    end
  end
end

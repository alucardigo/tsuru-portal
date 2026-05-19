require "rails_helper"

RSpec.describe Demand, type: :model do
  describe "TRL validation" do
    let(:demand) { build(:demand) }

    (1..9).each do |n|
      it "accepts TRL #{n}" do
        demand.trl = n
        expect(demand).to be_valid
      end
    end

    it "accepts nil TRL" do
      demand.trl = nil
      expect(demand).to be_valid
    end

    it "rejects TRL 0" do
      demand.trl = 0
      expect(demand).not_to be_valid
    end

    it "rejects TRL 10" do
      demand.trl = 10
      expect(demand).not_to be_valid
    end
  end

  describe "ODS goals validation" do
    let(:demand) { build(:demand) }

    it "accepts valid ODS goals 1-17" do
      demand.ods_goals = [ 1, 9, 17 ]
      expect(demand).to be_valid
    end

    it "rejects ODS goal 0" do
      demand.ods_goals = [ 0 ]
      expect(demand).not_to be_valid
    end

    it "rejects ODS goal 18" do
      demand.ods_goals = [ 18 ]
      expect(demand).not_to be_valid
    end

    it "accepts empty array" do
      demand.ods_goals = []
      expect(demand).to be_valid
    end
  end

  describe "#to_formpd" do
    subject(:json) { demand.to_formpd }

    let(:user) { create(:user, name: "Ana Lima") }
    let(:demand) do
      create(:demand, :elegivel_state,
             user: user,
             title: "Otimização de índice PostgreSQL",
             trl: 5,
             ods_goals: [ 9, 17 ])
    end


    it "includes schema version" do
      expect(json[:schema_versao]).to eq("FORMPD-2025")
    end

    it "includes demand id" do
      expect(json[:id]).to eq(demand.id)
    end

    it "includes titulo" do
      expect(json[:titulo]).to eq(demand.title)
    end

    it "includes solicitante" do
      expect(json[:solicitante]).to eq("Ana Lima")
    end

    it "includes estado" do
      expect(json[:estado]).to eq("elegivel")
    end

    it "includes trl" do
      expect(json[:trl]).to eq(5)
    end

    it "includes ods_goals" do
      expect(json[:ods]).to eq([ 9, 17 ])
    end

    it "includes data_criacao in ISO8601" do
      expect(json[:data_criacao]).to match(/\d{4}-\d{2}-\d{2}/)
    end

    it "includes avaliacao_n2" do
      expect(json[:avaliacao_n2]).to be_a(Hash)
    end
  end
end

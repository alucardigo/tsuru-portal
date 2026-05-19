require "rails_helper"

RSpec.describe Demand, type: :model do
  describe "scope busca_titulo" do
    before do
      create(:demand, title: "Aprendizado de Máquina aplicado")
      create(:demand, title: "Automação industrial RPA")
    end

    it "retorna demands com título matching (case-insensitive)" do
      result = described_class.busca_titulo("máquina")
      expect(result.map(&:title)).to include("Aprendizado de Máquina aplicado")
      expect(result.map(&:title)).not_to include("Automação industrial RPA")
    end

    it "retorna todos quando q é nil" do
      expect(described_class.busca_titulo(nil).count).to eq(2)
    end

    it "retorna todos quando q é string vazia" do
      expect(described_class.busca_titulo("").count).to eq(2)
    end
  end

  describe "scope por_trl" do
    before do
      create(:demand, trl: 3)
      create(:demand, trl: 7)
    end

    it "filtra por TRL exato" do
      expect(described_class.por_trl(3).pluck(:trl)).to all(eq(3))
    end

    it "retorna todos quando trl é nil" do
      expect(described_class.por_trl(nil).count).to eq(2)
    end
  end

  describe "scope de/ate" do
    let!(:old) { create(:demand, created_at: 60.days.ago) }
    let!(:recent) { create(:demand, created_at: 1.day.ago) }

    it "de filtra por data_ini inclusive" do
      result = described_class.de(30.days.ago.to_date)
      expect(result).to include(recent)
      expect(result).not_to include(old)
    end

    it "ate filtra por data_fim inclusive" do
      result = described_class.ate(30.days.ago.to_date)
      expect(result).to include(old)
      expect(result).not_to include(recent)
    end

    it "combina de+ate para intervalo" do
      result = described_class.de(65.days.ago.to_date).ate(30.days.ago.to_date)
      expect(result).to include(old)
      expect(result).not_to include(recent)
    end
  end

  describe "validações TRL e ODS" do
    it "aceita TRL nil" do
      expect(build(:demand, trl: nil)).to be_valid
    end

    it "aceita TRL 1..9" do
      (1..9).each do |n|
        expect(build(:demand, trl: n)).to be_valid
      end
    end

    it "rejeita TRL 0 ou 10" do
      expect(build(:demand, trl: 0)).not_to be_valid
      expect(build(:demand, trl: 10)).not_to be_valid
    end

    it "aceita ods_goals vazio" do
      expect(build(:demand, ods_goals: [])).to be_valid
    end

    it "aceita ods_goals com valores 1..17" do
      expect(build(:demand, ods_goals: [ 1, 9, 17 ])).to be_valid
    end

    it "rejeita ods_goals com valor 0 ou 18" do
      expect(build(:demand, ods_goals: [ 0 ])).not_to be_valid
      expect(build(:demand, ods_goals: [ 18 ])).not_to be_valid
    end
  end

  describe "#to_formpd" do
    let(:user) { create(:user) }
    let(:demand) { create(:demand, user: user, trl: 5, ods_goals: [ 9, 13 ]) }

    subject(:formpd) { demand.to_formpd }

    it "inclui schema_versao FORMPD-2025" do
      expect(formpd[:schema_versao]).to eq("FORMPD-2025")
    end

    it "inclui id, titulo, estado" do
      expect(formpd[:id]).to eq(demand.id)
      expect(formpd[:titulo]).to eq(demand.title)
      expect(formpd[:estado]).to eq(demand.aasm_state)
    end

    it "inclui TRL e ODS" do
      expect(formpd[:trl]).to eq(5)
      expect(formpd[:ods]).to contain_exactly(9, 13)
    end

    it "inclui data_criacao em formato ISO 8601" do
      expect(formpd[:data_criacao]).to match(/\d{4}-\d{2}-\d{2}/)
    end
  end
end

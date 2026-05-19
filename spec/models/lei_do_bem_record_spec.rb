require "rails_helper"

RSpec.describe LeiDoBemRecord, type: :model do
  describe "validacoes" do
    it { expect(build(:lei_do_bem_record)).to be_valid }

    it "exige ano_base" do
      expect(build(:lei_do_bem_record, ano_base: nil)).not_to be_valid
    end

    it "rejeita natureza invalida" do
      expect(build(:lei_do_bem_record, natureza_projeto: "qualquer")).not_to be_valid
    end

    it "aceita trl 1-9" do
      (1..9).each do |n|
        expect(build(:lei_do_bem_record, trl_inicial: n)).to be_valid
      end
    end

    it "rejeita ods fora 1-17" do
      expect(build(:lei_do_bem_record, ods_projeto: [ 0, 18 ])).not_to be_valid
    end
  end

  describe "associations" do
    let(:record) { create(:lei_do_bem_record) }

    it "tem expenses" do
      create(:expense, lei_do_bem_record: record)
      expect(record.expenses.count).to eq(1)
    end

    it "tem team_members" do
      create(:team_member, lei_do_bem_record: record)
      expect(record.team_members.count).to eq(1)
    end

    it "tem partnerships" do
      create(:partnership, lei_do_bem_record: record)
      expect(record.partnerships.count).to eq(1)
    end
  end
end

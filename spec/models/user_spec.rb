require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "validações" do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end

  describe "roles" do
    it "tem role padrão :colaborador" do
      expect(user).to be_colaborador
    end

    it "pode ser gestor" do
      user.role = :gestor
      expect(user).to be_gestor
    end

    it "pode ser analista_pdi" do
      user.role = :analista_pdi
      expect(user).to be_analista_pdi
    end

    it "pode ser admin" do
      user.role = :admin
      expect(user).to be_admin
    end

    it "pode ser board" do
      user.role = :board
      expect(user).to be_board
    end
  end

  describe "PaperTrail" do
    it { is_expected.to be_a(PaperTrail::Model::InstanceMethods) }
  end

  describe "#display_name" do
    it "retorna o name quando presente" do
      user.name = "Rodrigo Faria"
      expect(user.display_name).to eq("Rodrigo Faria")
    end

    it "retorna a parte local do email como fallback" do
      user.name = nil
      user.email = "rodrigo@bellube.com.br"
      expect(user.display_name).to eq("rodrigo")
    end
  end

  describe "#initials" do
    it "retorna as iniciais do nome" do
      user.name = "Rodrigo Faria"
      expect(user.initials).to eq("RF")
    end

    it "retorna inicial do email quando sem nome" do
      user.name = nil
      user.email = "rodrigo@example.com"
      expect(user.initials).to eq("R")
    end
  end
end

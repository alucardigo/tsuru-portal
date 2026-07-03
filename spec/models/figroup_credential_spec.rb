require "rails_helper"

RSpec.describe FiGroupCredential, type: :model do
  describe "#active?" do
    it "é falso quando expires_at está em branco" do
      cred = described_class.new(expires_at: nil)
      expect(cred.active?).to be(false)
    end

    it "é falso quando expires_at já passou" do
      cred = described_class.new(expires_at: 1.hour.ago)
      expect(cred.active?).to be(false)
    end

    it "é verdadeiro quando expires_at está no futuro" do
      cred = described_class.new(expires_at: 1.hour.from_now)
      expect(cred.active?).to be(true)
    end
  end

  describe ".active (scope)" do
    it "inclui apenas credenciais não expiradas" do
      ativa = described_class.create!(expires_at: 1.hour.from_now)
      described_class.create!(expires_at: 1.hour.ago)

      expect(described_class.active).to contain_exactly(ativa)
    end
  end

  describe "#service_id_for" do
    let(:credential) do
      described_class.new(
        service_ids: { "2025" => "sid-2025", "2026" => "053c4f53-a374-4c51-f584-08de93d6c24c" }
      )
    end

    it "retorna o uuid do ano informado como inteiro" do
      expect(credential.service_id_for(2026)).to eq("053c4f53-a374-4c51-f584-08de93d6c24c")
    end

    it "retorna o uuid do ano informado como string" do
      expect(credential.service_id_for("2025")).to eq("sid-2025")
    end

    it "retorna nil para ano ausente" do
      expect(credential.service_id_for(2099)).to be_nil
    end

    it "não quebra quando service_ids é nil" do
      cred = described_class.new(service_ids: nil)
      expect(cred.service_id_for(2026)).to be_nil
    end
  end

  describe ".current" do
    it "retorna a credencial criada mais recentemente" do
      described_class.create!(expires_at: 1.hour.from_now, created_at: 2.days.ago)
      recente = described_class.create!(expires_at: 1.hour.from_now, created_at: 1.minute.ago)

      expect(described_class.current).to eq(recente)
    end

    it "retorna nil quando não há credenciais" do
      expect(described_class.current).to be_nil
    end
  end

  describe "criptografia do token" do
    it "expõe o token em texto puro via atributo" do
      cred = described_class.create!(token: "jwt-secreto", expires_at: 1.hour.from_now)
      expect(cred.reload.token).to eq("jwt-secreto")
    end
  end
end

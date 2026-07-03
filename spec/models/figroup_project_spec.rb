require "rails_helper"

RSpec.describe FiGroupProject, type: :model do
  describe ".normalize_code" do
    it "remove espaços e uniformiza maiúsculas" do
      expect(described_class.normalize_code("INOVA BEL 013")).to eq("INOVABEL013")
    end

    it "remove hífens (chave de vínculo tolerante a formatação)" do
      expect(described_class.normalize_code("INOVA BEL-013")).to eq("INOVABEL013")
    end

    it "trata os dois formatos como equivalentes" do
      expect(described_class.normalize_code("INOVA BEL 013"))
        .to eq(described_class.normalize_code("INOVA BEL-013"))
    end

    it "converte minúsculas para maiúsculas" do
      expect(described_class.normalize_code("inova bel 013")).to eq("INOVABEL013")
    end

    it "retorna string vazia para nil" do
      expect(described_class.normalize_code(nil)).to eq("")
    end
  end

  describe "#eligibility_label" do
    it "mapeia o inteiro de elegibilidade para o rótulo (via FieldMap)" do
      project = described_class.new(eligibility: 1)
      expect(project.eligibility_label).to eq("Elegível")
    end

    it "retorna 'Não Elegível' para 2" do
      project = described_class.new(eligibility: 2)
      expect(project.eligibility_label).to eq("Não Elegível")
    end

    it "retorna nil para valor desconhecido" do
      project = described_class.new(eligibility: 99)
      expect(project.eligibility_label).to be_nil
    end
  end

  describe "#linked?" do
    it "é verdadeiro quando há demand vinculada" do
      demand = create(:demand)
      project = described_class.new(fi_project_id: "uuid-1", demand: demand)
      expect(project.linked?).to be(true)
    end

    it "é falso quando não há demand vinculada" do
      project = described_class.new(fi_project_id: "uuid-2", demand: nil)
      expect(project.linked?).to be(false)
    end
  end
end

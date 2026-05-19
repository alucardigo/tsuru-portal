require "rails_helper"

RSpec.describe Validators::FormpdSchema, type: :service do
  let(:valid_payload) do
    {
      schema_versao: "FORMPD-2025",
      id: 1,
      titulo: "Projeto de IA para triagem patentes",
      solicitante: "Ana Pesquisadora",
      estado: "elegivel",
      trl: 5,
      ods: [ 9, 17 ],
      data_criacao: "2025-12-01",
      avaliacao_n2: {
        motivacao: "Reduzir tempo de analise",
        barreira_tecnica: "Modelo nao discrimina patentes prior art",
        metodologia: "Treinamento BERT em corpus INPI",
        resultado_obtido: "F1=0.87 em validacao cruzada"
      }
    }
  end

  describe "#call" do
    it "aceita payload valido" do
      result = described_class.call(payload: valid_payload)
      expect(result.success?).to be true
    end

    it "rejeita schema_versao desconhecida" do
      result = described_class.call(payload: valid_payload.merge(schema_versao: "FORMPD-1999"))
      expect(result.success?).to be false
      expect(result.errors.first).to include("schema_versao")
    end

    it "rejeita TRL fora 1-9" do
      result = described_class.call(payload: valid_payload.merge(trl: 10))
      expect(result.success?).to be false
    end

    it "rejeita ODS > 17" do
      result = described_class.call(payload: valid_payload.merge(ods: [ 20 ]))
      expect(result.success?).to be false
    end

    it "rejeita estado fora da lista" do
      result = described_class.call(payload: valid_payload.merge(estado: "wonderland"))
      expect(result.success?).to be false
    end

    it "rejeita data_criacao em formato errado" do
      result = described_class.call(payload: valid_payload.merge(data_criacao: "01/12/2025"))
      expect(result.success?).to be false
    end

    it "rejeita ODS duplicado" do
      result = described_class.call(payload: valid_payload.merge(ods: [ 9, 9 ]))
      expect(result.success?).to be false
    end

    it "aceita string JSON serializado" do
      result = described_class.call(payload: valid_payload.to_json)
      expect(result.success?).to be true
    end
  end
end

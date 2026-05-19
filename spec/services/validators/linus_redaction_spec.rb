require "rails_helper"

RSpec.describe Validators::LinusRedaction, type: :service do
  describe ".call" do
    context "when text is valid technical writing with quantitatives" do
      let(:tech_text) do
        "Reduzimos a latencia P99 de 480ms para 87ms no endpoint /search " \
        "atraves de reescrita do indice B-tree para LSM-Tree."
      end

      it "aceita texto tecnico com latencia P99 em ms", :aggregate_failures do
        result = described_class.call(text: tech_text)
        expect(result.success?).to be true
        expect(result.payload[:text]).to eq(tech_text)
        expect(result.payload[:length]).to eq(tech_text.length)
      end

      it "aceita texto com percentual e R$" do
        text = "O custo de infraestrutura caiu 42% (de R$ 18.500,00/mes para " \
               "R$ 10.730,00/mes) apos a migracao para arquitetura serverless."
        expect(described_class.call(text: text).success?).to be true
      end

      it "aceita texto com MB/GB (memoria)" do
        text = "O footprint do servico passou de 512 MB para 128 MB de RSS, " \
               "viabilizando deploy em nodes t3.micro."
        expect(described_class.call(text: text).success?).to be true
      end

      it "aceita unidade rps/req/s (throughput)" do
        text = "Throughput aumentou de 1200 rps para 4800 req/s no benchmark wrk -c200."
        expect(described_class.call(text: text).success?).to be true
      end
    end

    context "when require_quantitative is disabled" do
      it "aceita texto sem quantitativos" do
        text = "Investigacao exploratoria sobre comportamento do GC em alta concorrencia."
        expect(described_class.call(text: text, require_quantitative: false).success?).to be true
      end

      it "aceita texto vazio" do
        expect(described_class.call(text: "", require_quantitative: false).success?).to be true
      end
    end

    context "when text contains banned vague phrases" do
      it "rejeita 'ficou mais rapido' (sem acento)" do
        text = "Apos a refatoracao, o sistema ficou mais rapido em 30%."
        result = described_class.call(text: text)
        expect(result.errors.map { |v| v[:type] }).to include(:banned_phrase)
      end

      it "rejeita 'ficou mais rapido' com acentuacao tolerada" do
        text = "Apos a refatoracao, o sistema ficou mais rapido em 30%."
        expect(described_class.call(text: text).success?).to be false
      end

      it "rejeita 'melhorou' (termo vago)" do
        text = "A performance melhorou substancialmente apos a otimizacao do indice " \
               "em 25% de reducao de latencia."
        result = described_class.call(text: text)
        banned = result.errors.find { |v| v[:type] == :banned_phrase }
        expect(banned[:terms]).to include("melhorou")
      end

      it "rejeita 'ganho expressivo' (subjetivo)" do
        text = "Tivemos ganho expressivo de 15% na latencia P99 e reducao de 200ms."
        expect(described_class.call(text: text).success?).to be false
      end

      it "e case-insensitive (FICOU MAIS RAPIDO em caixa alta)" do
        text = "FICOU MAIS RAPIDO em 30% no benchmark P99."
        result = described_class.call(text: text)
        banned = result.errors.find { |v| v[:type] == :banned_phrase }
        expect(banned[:terms]).to include("ficou mais rapido")
      end
    end

    context "when text disguises PMO issues as technical barriers" do
      it "rejeita 'prazo apertado'" do
        text = "A barreira tecnica foi o prazo apertado de 2 semanas para entregar " \
               "o sprint com latencia P99 < 100ms."
        result = described_class.call(text: text)
        expect(result.errors.map { |v| v[:type] }).to include(:pmo_disguised_as_technical)
      end

      it "rejeita 'equipe sem treinamento'" do
        text = "Enfrentamos equipe sem treinamento adequado em LSM-Tree, " \
               "atingimos 87ms de P99 mesmo assim."
        expect(described_class.call(text: text).success?).to be false
      end

      it "rejeita 'orcamento limitado' sem acentuacao" do
        text = "O orcamento limitado de R$ 50.000 obrigou trade-off de 150ms vs custo."
        expect(described_class.call(text: text).success?).to be false
      end

      it "rejeita 'orçamento limitado' com acentuacao" do
        text = "O orçamento limitado de R$ 50.000 obrigou trade-off de 150ms vs custo."
        expect(described_class.call(text: text).success?).to be false
      end
    end

    context "when quantitative metrics are missing" do
      it "rejeita texto sem numeros/unidades por default", :aggregate_failures do
        text = "Estudo exploratorio sobre paradigmas reativos em sistemas distribuidos."
        result = described_class.call(text: text)
        expect(result.success?).to be false
        expect(result.errors.map { |v| v[:type] }).to include(:missing_quantitative)
      end

      it "rejeita texto vazio por default", :aggregate_failures do
        result = described_class.call(text: "")
        expect(result.success?).to be false
        expect(result.errors.map { |v| v[:type] }).to include(:missing_quantitative)
      end

      it "rejeita texto nil (sem quantitativos)" do
        expect(described_class.call(text: nil).success?).to be false
      end
    end

    context "with multiple violation types" do
      it "reporta todas violations no mesmo texto", :aggregate_failures do
        text = "O sistema ficou mais rapido devido ao prazo apertado da sprint."
        result = described_class.call(text: text)
        types = result.errors.map { |v| v[:type] }
        expect(types).to include(:banned_phrase, :pmo_disguised_as_technical, :missing_quantitative)
        expect(result.errors.size).to be >= 3
      end

      it "retorna reason explicitando glosa Lei do Bem" do
        text = "Melhorou bastante."
        result = described_class.call(text: text)
        expect(result.reason).to match(/glosa.*Lei do Bem/i)
      end
    end

    context "with Result struct contract" do
      it "expoe success? como boolean" do
        result = described_class.call(text: "P99 87ms.")
        expect(result.success?).to be(true).or be(false)
      end

      it "expoe payload em sucesso" do
        ok = described_class.call(text: "Latencia P99 = 87ms.")
        expect(ok.payload).to be_a(Hash)
      end

      it "expoe errors em falha" do
        ko = described_class.call(text: "ficou mais rapido demais", require_quantitative: false)
        expect(ko.errors).to be_an(Array)
      end
    end
  end
end

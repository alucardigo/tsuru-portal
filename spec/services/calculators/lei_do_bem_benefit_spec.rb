require "rails_helper"

RSpec.describe Calculators::LeiDoBemBenefit, type: :service do
  let(:record) do
    create(:lei_do_bem_record,
           total_dispendios: BigDecimal("100000.00"),
           base_zero_pesquisadores: false,
           tem_patente: false,
           regime_tributacao: "lucro_real_anual")
  end

  describe ".call" do
    context "with cenario basico - 60% sem adicionais" do
      subject(:result) { described_class.call(record: record) }

      it "retorna success? true" do
        expect(result.success?).to be true
      end

      it "aplica percentual de 60%" do
        expect(result.payload[:percentual_aplicado]).to eq(BigDecimal("0.60"))
      end

      it "exclusao_base = 60.000,00" do
        expect(result.payload[:exclusao_base]).to eq(BigDecimal("60000.00"))
      end

      it "nao tem adicional pesquisadores" do
        expect(result.payload[:adicional_pesquisadores]).to eq(BigDecimal("0"))
      end

      it "nao tem adicional patente" do
        expect(result.payload[:adicional_patente]).to eq(BigDecimal("0"))
      end

      it "exclusao_total = 60.000,00" do
        expect(result.payload[:exclusao_total]).to eq(BigDecimal("60000.00"))
      end

      it "economia tributaria = 60.000 * 0,34 = 20.400,00" do
        expect(result.payload[:economia_tributaria]).to eq(BigDecimal("20400.00"))
      end

      it "retorna dispendios originais" do
        expect(result.payload[:dispendios]).to eq(BigDecimal("100000.00"))
      end
    end

    context "with adicional pesquisadores base_zero (80%)" do
      subject(:result) { described_class.call(record: record) }

      let(:record) do
        create(:lei_do_bem_record,
               total_dispendios: BigDecimal("100000.00"),
               base_zero_pesquisadores: true,
               tem_patente: false)
      end

      it "percentual aplicado total = 0,80" do
        expect(result.payload[:percentual_aplicado]).to eq(BigDecimal("0.80"))
      end

      it "adicional pesquisadores = 20.000,00" do
        expect(result.payload[:adicional_pesquisadores]).to eq(BigDecimal("20000.00"))
      end

      it "exclusao_total = 80.000,00" do
        expect(result.payload[:exclusao_total]).to eq(BigDecimal("80000.00"))
      end

      it "economia tributaria = 80.000 * 0,34 = 27.200,00" do
        expect(result.payload[:economia_tributaria]).to eq(BigDecimal("27200.00"))
      end
    end

    context "with adicional patente (80%)" do
      subject(:result) { described_class.call(record: record) }

      let(:record) do
        create(:lei_do_bem_record,
               total_dispendios: BigDecimal("100000.00"),
               base_zero_pesquisadores: false,
               tem_patente: true)
      end

      it "percentual aplicado total = 0,80" do
        expect(result.payload[:percentual_aplicado]).to eq(BigDecimal("0.80"))
      end

      it "adicional patente = 20.000,00" do
        expect(result.payload[:adicional_patente]).to eq(BigDecimal("20000.00"))
      end

      it "adicional pesquisadores = 0" do
        expect(result.payload[:adicional_pesquisadores]).to eq(BigDecimal("0"))
      end

      it "economia tributaria = 27.200,00" do
        expect(result.payload[:economia_tributaria]).to eq(BigDecimal("27200.00"))
      end
    end

    context "with ambos adicionais (100%)" do
      subject(:result) { described_class.call(record: record) }

      let(:record) do
        create(:lei_do_bem_record,
               total_dispendios: BigDecimal("100000.00"),
               base_zero_pesquisadores: true,
               tem_patente: true)
      end

      it "percentual aplicado total = 1,00" do
        expect(result.payload[:percentual_aplicado]).to eq(BigDecimal("1.00"))
      end

      it "adicional pesquisadores = 20.000,00" do
        expect(result.payload[:adicional_pesquisadores]).to eq(BigDecimal("20000.00"))
      end

      it "adicional patente = 20.000,00" do
        expect(result.payload[:adicional_patente]).to eq(BigDecimal("20000.00"))
      end

      it "exclusao_total = 100.000,00 (100% dos dispendios)" do
        expect(result.payload[:exclusao_total]).to eq(BigDecimal("100000.00"))
      end

      it "economia tributaria = 100.000 * 0,34 = 34.000,00" do
        expect(result.payload[:economia_tributaria]).to eq(BigDecimal("34000.00"))
      end
    end

    context "when comparing regime anual vs trimestral (mesma formula)" do
      let(:anual) do
        create(:lei_do_bem_record,
               total_dispendios: BigDecimal("250000.00"),
               regime_tributacao: "lucro_real_anual")
      end
      let(:trimestral) do
        create(:lei_do_bem_record,
               total_dispendios: BigDecimal("250000.00"),
               regime_tributacao: "lucro_real_trimestral")
      end

      it "produz mesmo valor de economia em ambos regimes" do
        r_anual = described_class.call(record: anual)
        r_trim  = described_class.call(record: trimestral)
        expect(r_anual.payload[:economia_tributaria]).to eq(r_trim.payload[:economia_tributaria])
      end

      it "expoe o regime no payload" do
        r_anual = described_class.call(record: anual)
        expect(r_anual.payload[:regime_tributacao]).to eq("lucro_real_anual")
      end

      it "expoe regime trimestral no payload" do
        r_trim = described_class.call(record: trimestral)
        expect(r_trim.payload[:regime_tributacao]).to eq("lucro_real_trimestral")
      end
    end

    context "with total_dispendios = 0 (edge case)" do
      subject(:result) { described_class.call(record: record) }

      let(:record) do
        create(:lei_do_bem_record,
               total_dispendios: BigDecimal("0"),
               base_zero_pesquisadores: true,
               tem_patente: true)
      end

      it "retorna success? true" do
        expect(result.success?).to be true
      end

      it "exclusao_total zero" do
        expect(result.payload[:exclusao_total]).to eq(BigDecimal("0"))
      end

      it "economia tributaria zero" do
        expect(result.payload[:economia_tributaria]).to eq(BigDecimal("0"))
      end
    end

    context "when record is nil (edge case)" do
      subject(:result) { described_class.call(record: nil) }

      it "retorna success? false" do
        expect(result.success?).to be false
      end

      it "informa reason :invalid_record" do
        expect(result.reason).to eq(:invalid_record)
      end

      it "popula errors com mensagem" do
        expect(result.errors).to include(match(/record/i))
      end

      it "payload nil ou vazio" do
        expect(result.payload).to be_nil.or be_empty
      end
    end

    context "with precisao BigDecimal (centavos)" do
      subject(:result) { described_class.call(record: record) }

      let(:record) do
        create(:lei_do_bem_record,
               total_dispendios: BigDecimal("33333.33"),
               base_zero_pesquisadores: false,
               tem_patente: false)
      end

      it "dispendios e BigDecimal" do
        expect(result.payload[:dispendios]).to be_a(BigDecimal)
      end

      it "exclusao_base e BigDecimal" do
        expect(result.payload[:exclusao_base]).to be_a(BigDecimal)
      end

      it "exclusao_total e BigDecimal" do
        expect(result.payload[:exclusao_total]).to be_a(BigDecimal)
      end

      it "economia_tributaria e BigDecimal" do
        expect(result.payload[:economia_tributaria]).to be_a(BigDecimal)
      end

      it "exclusao_base preserva centavos (33333,33 * 0,60 = 20000,00 com rounding)" do
        expect(result.payload[:exclusao_base]).to eq(BigDecimal("20000.00"))
      end

      it "economia tributaria com arredondamento 2 casas (20000 * 0,34 = 6800,00)" do
        expect(result.payload[:economia_tributaria]).to eq(BigDecimal("6800.00"))
      end

      it "nao usa Float em economia tributaria" do
        expect(result.payload[:economia_tributaria]).not_to be_a(Float)
      end
    end

    context "with total_dispendios negativo (rejeita)" do
      subject(:result) { described_class.call(record: record) }

      let(:record) do
        build(:lei_do_bem_record, total_dispendios: BigDecimal("-100.00")).tap do |r|
          r.save(validate: false)
        end
      end

      it "retorna failure" do
        expect(result.success?).to be false
      end

      it "reason :invalid_dispendios" do
        expect(result.reason).to eq(:invalid_dispendios)
      end
    end
  end

  describe "Result struct" do
    it "expoe success?, payload, reason, errors" do
      result = described_class.call(record: record)
      expect(result).to respond_to(:success?, :payload, :reason, :errors)
    end
  end
end

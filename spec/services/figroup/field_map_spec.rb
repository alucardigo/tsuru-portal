require "rails_helper"

RSpec.describe FiGroup::FieldMap, type: :service do
  # Objeto FI de exemplo, no shape de GET /Projects/{id} (ver contrato).
  # 'why' e 'techChallenge' têm valores originais que devem ser sobrescritos
  # pelo Tsuru; os demais campos não devem ser tocados.
  let(:fi_object) do
    {
      "id"                    => "2d081d30-aaaa-bbbb-cccc-000000000000",
      "serviceId"             => "053c4f53-a374-4c51-f584-08de93d6c24c",
      "name"                  => "MITRA – Projeto FI",
      "area"                  => 3,
      "tipology"              => 2,
      "nature"                => 2,
      "escope"                => 3,
      "why"                   => "motivação ORIGINAL da FI",
      "objective"             => "objetivo original da FI",
      "how"                   => "",
      "who"                   => "",
      "techChallenge"         => "barreira ORIGINAL da FI",
      "advances"              => "",
      "techUsed"              => "",
      "eligibility"           => 1,
      "positionFI"            => "parecer FI",
      "codeProject"           => "INOVA BEL 013",
      "developmentPlanning"   => "metodologia original da FI",
      "beforeAfterDifference" => "benchmark original da FI"
    }
  end

  # Demand com apenas motivacao e barreira_tecnica preenchidos.
  # Os demais campos N2 ficam em branco de propósito (n2_assessment vazio).
  let(:demand) do
    build(
      :demand,
      title: "",
      solucao_proposta: nil,
      n2_assessment: {
        "motivacao"        => "motivação DO TSURU",
        "barreira_tecnica" => "barreira DO TSURU"
      }
    )
  end

  describe ".demand_attrs_from_fi" do
    it "retorna apenas atributos com valor presente no objeto FI" do
      attrs = described_class.demand_attrs_from_fi(fi_object)

      expect(attrs[:motivacao]).to eq("motivação ORIGINAL da FI")
      expect(attrs[:solucao_proposta]).to eq("objetivo original da FI")
      expect(attrs[:barreira_tecnica]).to eq("barreira ORIGINAL da FI")
      expect(attrs[:title]).to eq("MITRA – Projeto FI")
      expect(attrs[:metodologia]).to eq("metodologia original da FI")
      expect(attrs[:benchmark_anterior]).to eq("benchmark original da FI")
    end

    it "pula campos FI em branco" do
      attrs = described_class.demand_attrs_from_fi(fi_object)

      # advances/techUsed estão vazios ("") no fi_object => devem ser omitidos
      expect(attrs).not_to have_key(:resultado_obtido)
      expect(attrs).not_to have_key(:stack_tecnologico)
    end
  end

  describe ".apply_tsuru_onto_fi" do
    subject(:result) { described_class.apply_tsuru_onto_fi(fi_object, demand) }

    it "sobrescreve 'why' com a motivacao do Tsuru" do
      expect(result["why"]).to eq("motivação DO TSURU")
    end

    it "sobrescreve 'techChallenge' com a barreira_tecnica do Tsuru" do
      expect(result["techChallenge"]).to eq("barreira DO TSURU")
    end

    it "preserva os campos FI que o Tsuru não preencheu" do
      expect(result["objective"]).to eq("objetivo original da FI")
      expect(result["developmentPlanning"]).to eq("metodologia original da FI")
      expect(result["beforeAfterDifference"]).to eq("benchmark original da FI")
    end

    it "preserva todos os campos não-mapeados do objeto FI (PUT do objeto inteiro)" do
      expect(result["id"]).to eq(fi_object["id"])
      expect(result["serviceId"]).to eq(fi_object["serviceId"])
      expect(result["eligibility"]).to eq(1)
      expect(result["positionFI"]).to eq("parecer FI")
      expect(result["codeProject"]).to eq("INOVA BEL 013")
      expect(result["area"]).to eq(3)
      expect(result["nature"]).to eq(2)
    end

    it "não sobrescreve com valores em branco do Tsuru" do
      # 'name' mapeia para title, que está "" na demand => 'name' original preservado
      expect(result["name"]).to eq("MITRA – Projeto FI")
      # 'objective' mapeia para solucao_proposta (nil) => original preservado
      expect(result["objective"]).to eq("objetivo original da FI")
    end

    it "não muta o objeto FI original" do
      original = fi_object.dup
      described_class.apply_tsuru_onto_fi(fi_object, demand)
      expect(fi_object).to eq(original)
    end
  end

  describe ".diff" do
    subject(:changes) { described_class.diff(fi_object, demand) }

    it "reporta apenas os campos que apply_tsuru_onto_fi mudaria" do
      expect(changes.keys).to contain_exactly("why", "techChallenge")
    end

    it "descreve de/para de cada mudança" do
      expect(changes["why"]).to eq(de: "motivação ORIGINAL da FI", para: "motivação DO TSURU")
      expect(changes["techChallenge"]).to eq(de: "barreira ORIGINAL da FI", para: "barreira DO TSURU")
    end

    it "é vazio quando o Tsuru não altera nada" do
      demand_vazia = build(:demand, title: "", solucao_proposta: nil, n2_assessment: {})
      expect(described_class.diff(fi_object, demand_vazia)).to eq({})
    end
  end
end

require "rails_helper"

RSpec.describe Demand, type: :model do
  subject(:demand) { build(:demand) }

  describe "validações" do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_length_of(:title).is_at_most(200) }
    it { is_expected.to belong_to(:user) }
  end

  describe "estado inicial" do
    it "começa como rascunho" do
      expect(demand).to be_rascunho
    end
  end

  describe "transições de estado" do
    let(:demand) { create(:demand) }

    it "submeter move rascunho → submetida" do
      demand.submeter!
      expect(demand).to be_submetida
    end

    it "iniciar_triagem move submetida → em_triagem" do
      demand.update!(aasm_state: "submetida")
      demand.iniciar_triagem!
      expect(demand).to be_em_triagem
    end

    it "aprovar_n1 move em_triagem → n1_aprovada" do
      demand.update!(aasm_state: "em_triagem")
      demand.aprovar_n1!
      expect(demand).to be_n1_aprovada
    end

    it "reprovar_n1 move em_triagem → n1_reprovada" do
      demand.update!(aasm_state: "em_triagem")
      demand.reprovar_n1!
      expect(demand).to be_n1_reprovada
    end

    it "cancelar pode ser feito em qualquer estado ativo" do
      demand.submeter!
      demand.cancelar!
      expect(demand).to be_cancelada
    end

    it "não permite submeter de n1_aprovada" do
      demand.update!(aasm_state: "n1_aprovada")
      expect { demand.submeter! }.to raise_error(StateMachines::InvalidTransition)
    end
  end

  describe "N1 triagem Lei do Bem" do
    it "reprovado_n1? é false quando n1_flags está vazio" do
      demand.n1_flags = {}
      expect(demand.reprovado_n1?).to be false
    end

    it "reprovado_n1? é true quando qualquer flag N1 for true" do
      demand.n1_flags = { "rotina_operacional" => true }
      expect(demand.reprovado_n1?).to be true
    end
  end

  describe "PaperTrail" do
    it { is_expected.to be_a(PaperTrail::Model::InstanceMethods) }
  end

  describe "#linus_violations (Lei do Bem redacao)" do
    it "retorna violations quando barreira_tecnica usa termos banidos sem quantitativos" do
      demand.n2_assessment = { "barreira_tecnica" => "O sistema ficou mais rapido depois" }
      types = demand.linus_violations.map { |v| v[:type] }
      expect(types).to include(:banned_phrase, :missing_quantitative)
    end
  end
end

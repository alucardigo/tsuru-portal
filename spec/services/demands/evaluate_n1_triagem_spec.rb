require "rails_helper"

RSpec.describe Demands::EvaluateN1Triagem, type: :service do
  let(:gestor) { create(:user, :gestor) }
  let(:colaborador) { create(:user) }
  let(:demand) { create(:demand, :em_triagem, user: colaborador) }

  let(:flags_all_zero) do
    { "rotina_operacional" => false, "adequacao_normativa" => false,
      "solucao_prateleira" => false, "trl_fora_janela" => false,
      "escopo_nao_tecnologico" => false }
  end

  let(:flags_with_one_set) do
    flags_all_zero.merge("rotina_operacional" => true)
  end

  describe ".call" do
    context "quando nenhum flag N1 marcado (aprovação)" do
      it "transiciona demanda para n1_aprovada" do
        described_class.call(demand: demand, actor: gestor, flags: flags_all_zero)
        expect(demand.reload).to be_n1_aprovada
      end

      it "retorna Result com success? true e outcome :aprovada" do
        result = described_class.call(demand: demand, actor: gestor, flags: flags_all_zero)
        expect(result).to be_success
        expect(result.payload[:outcome]).to eq(:aprovada)
        expect(result.payload[:demand]).to eq(demand)
      end

      it "envia DemandMailer.n1_aprovada (side effect)" do
        expect {
          described_class.call(demand: demand, actor: gestor, flags: flags_all_zero)
        }.to have_enqueued_mail(DemandMailer, :n1_aprovada).with(demand)
      end
    end

    context "quando algum flag N1 marcado (reprovação)" do
      it "transiciona demanda para n1_reprovada" do
        described_class.call(demand: demand, actor: gestor, flags: flags_with_one_set)
        expect(demand.reload).to be_n1_reprovada
      end

      it "retorna Result com success? true e outcome :reprovada" do
        result = described_class.call(demand: demand, actor: gestor, flags: flags_with_one_set)
        expect(result).to be_success
        expect(result.payload[:outcome]).to eq(:reprovada)
      end

      it "envia DemandMailer.n1_reprovada (side effect)" do
        expect {
          described_class.call(demand: demand, actor: gestor, flags: flags_with_one_set)
        }.to have_enqueued_mail(DemandMailer, :n1_reprovada).with(demand)
      end
    end

    context "quando demand não está em em_triagem (transição inválida)" do
      let(:demand_submetida) { create(:demand, :submetida, user: colaborador) }

      it "retorna Result com success? false e reason :invalid_transition" do
        result = described_class.call(demand: demand_submetida, actor: gestor, flags: flags_all_zero)
        expect(result).not_to be_success
        expect(result.reason).to eq(:invalid_transition)
      end

      it "não envia email (rollback de side effects)" do
        expect {
          described_class.call(demand: demand_submetida, actor: gestor, flags: flags_all_zero)
        }.not_to have_enqueued_mail(DemandMailer, :n1_aprovada)
      end
    end

    context "quando save! falha por validação (RecordInvalid)" do
      it "retorna Result com success? false e reason :validation" do
        allow(demand).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(demand))
        allow(demand).to receive_messages(reprovado_n1?: false, aprovar_n1: true)

        result = described_class.call(demand: demand, actor: gestor, flags: flags_all_zero)
        expect(result).not_to be_success
        expect(result.reason).to eq(:validation)
        expect(result.errors).to eq(demand.errors)
      end
    end
  end
end

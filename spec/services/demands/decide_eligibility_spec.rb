require "rails_helper"

RSpec.describe Demands::DecideEligibility, type: :service do
  let(:analista) { create(:user, :analista_pdi) }
  let(:colaborador) { create(:user) }
  let(:demand) { create(:demand, :n2_completa, user: colaborador) }
  let(:parecer) { "Incerteza tecnológica comprovada; barreira não trivial." }

  describe ".call" do
    context "quando decisão é :elegivel com parecer presente" do
      it "transiciona demanda para elegivel" do
        described_class.call(demand: demand, actor: analista,
                             decision: :elegivel, parecer_tecnico: parecer)
        expect(demand.reload).to be_elegivel
      end

      it "retorna Result com success? true e outcome :elegivel" do
        result = described_class.call(demand: demand, actor: analista,
                                      decision: :elegivel, parecer_tecnico: parecer)
        expect(result).to be_success
        expect(result.payload[:outcome]).to eq(:elegivel)
        expect(result.payload[:demand]).to eq(demand)
      end

      it "envia DemandMailer.elegivel (side effect)" do
        expect {
          described_class.call(demand: demand, actor: analista,
                               decision: :elegivel, parecer_tecnico: parecer)
        }.to have_enqueued_mail(DemandMailer, :elegivel).with(demand)
      end

      it "persiste parecer_tecnico no demand" do
        described_class.call(demand: demand, actor: analista,
                             decision: :elegivel, parecer_tecnico: parecer)
        expect(demand.reload.parecer_tecnico).to eq(parecer)
      end
    end

    context "quando decisão é :nao_elegivel com parecer presente" do
      it "transiciona demanda para nao_elegivel" do
        described_class.call(demand: demand, actor: analista,
                             decision: :nao_elegivel, parecer_tecnico: parecer)
        expect(demand.reload).to be_nao_elegivel
      end

      it "retorna Result com success? true e outcome :nao_elegivel" do
        result = described_class.call(demand: demand, actor: analista,
                                      decision: :nao_elegivel, parecer_tecnico: parecer)
        expect(result).to be_success
        expect(result.payload[:outcome]).to eq(:nao_elegivel)
      end

      it "não envia email de elegivel" do
        expect {
          described_class.call(demand: demand, actor: analista,
                               decision: :nao_elegivel, parecer_tecnico: parecer)
        }.not_to have_enqueued_mail(DemandMailer, :elegivel)
      end
    end

    context "quando parecer_tecnico está ausente" do
      it "retorna Result com success? false e reason :invalid_transition" do
        result = described_class.call(demand: demand, actor: analista,
                                      decision: :elegivel, parecer_tecnico: "")
        expect(result).not_to be_success
        expect(result.reason).to eq(:invalid_transition)
      end

      it "não transiciona o estado" do
        described_class.call(demand: demand, actor: analista,
                             decision: :elegivel, parecer_tecnico: nil)
        expect(demand.reload).to be_n2_completa
      end

      it "não envia email" do
        expect {
          described_class.call(demand: demand, actor: analista,
                               decision: :elegivel, parecer_tecnico: "")
        }.not_to have_enqueued_mail(DemandMailer, :elegivel)
      end
    end

    context "quando decisão é inválida" do
      it "retorna Result com success? false e reason :invalid_decision" do
        result = described_class.call(demand: demand, actor: analista,
                                      decision: :foobar, parecer_tecnico: parecer)
        expect(result).not_to be_success
        expect(result.reason).to eq(:invalid_decision)
      end
    end
  end
end

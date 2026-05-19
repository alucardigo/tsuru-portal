require "rails_helper"

RSpec.describe DemandMailer, type: :mailer do
  let!(:gestor) { create(:user, :gestor) }
  let(:colaborador) { create(:user) }
  let(:demand) { create(:demand, user: colaborador) }

  describe "#submetida" do
    subject(:mail) { described_class.submetida(demand) }

    it "envia para gestores" do
      expect(mail.to).to include(gestor.email)
    end

    it "tem assunto correto" do
      expect(mail.subject).to include("Nova demanda submetida")
    end

    it "menciona título da demanda no corpo" do
      expect(mail.body.encoded).to include(demand.title)
    end
  end

  describe "#n1_aprovada" do
    subject(:mail) { described_class.n1_aprovada(demand) }

    it "envia para o colaborador dono" do
      expect(mail.to).to include(colaborador.email)
    end

    it "tem assunto correto" do
      expect(mail.subject).to include("aprovada")
    end
  end

  describe "#n1_reprovada" do
    subject(:mail) { described_class.n1_reprovada(demand) }

    let(:demand) { create(:demand, :n1_reprovada_state, user: colaborador) }


    it "envia para o colaborador dono" do
      expect(mail.to).to include(colaborador.email)
    end

    it "tem assunto correto" do
      expect(mail.subject).to include("reprovada")
    end
  end

  describe "#elegivel" do
    subject(:mail) { described_class.elegivel(demand) }

    let(:demand) { create(:demand, :elegivel_state, user: colaborador) }


    it "envia para o colaborador dono" do
      expect(mail.to).to include(colaborador.email)
    end

    it "menciona Lei do Bem no corpo" do
      expect(mail.body.encoded).to include("Lei do Bem")
    end
  end
end

require "rails_helper"

RSpec.describe DemandDigestMailer, type: :mailer do
  let!(:gestor) { create(:user, role: "gestor") }
  let!(:analista) { create(:user, role: "analista_pdi") }
  let!(:colaborador) { create(:user, role: "colaborador") }
  let!(:demand_nova) { create(:demand, aasm_state: "submetida", created_at: 3.days.ago) }
  let!(:demand_elegivel) { create(:demand, aasm_state: "elegivel") }
  let!(:demand_antiga) { create(:demand, aasm_state: "submetida", created_at: 15.days.ago) }

  describe "#weekly_summary" do
    subject(:mail) { described_class.weekly_summary(gestor) }

    it "envia para o gestor" do
      expect(mail.to).to include(gestor.email)
    end

    it "assunto contém 'Resumo Semanal'" do
      expect(mail.subject).to include("Resumo Semanal")
    end

    it "corpo inclui total de demandas" do
      expect(mail.body.encoded).to include("demanda")
    end

    it "corpo inclui demandas submetidas na semana" do
      expect(mail.body.encoded).to include(demand_nova.title)
    end

    it "não inclui demand_antiga (fora da semana)" do
      expect(mail.body.encoded).not_to include(demand_antiga.title)
    end
  end
end

RSpec.describe "DemandDigestJob", type: :job do
  include ActiveJob::TestHelper

  it "enfileira emails para gestores e analistas" do
    create(:user, role: "gestor")
    create(:user, role: "analista_pdi")
    create(:user, role: "colaborador") # não deve receber

    expect do
      perform_enqueued_jobs { DemandDigestJob.perform_now }
    end.to change { ActionMailer::Base.deliveries.count }.by(2)
  end
end

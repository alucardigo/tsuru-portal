require "rails_helper"

RSpec.describe Notifications::Dispatcher, type: :service do
  let(:owner) { create(:user, role: "colaborador") }
  let(:gestor) { create(:user, role: "gestor") }
  let(:analista) { create(:user, role: "analista_pdi") }
  let(:demand) { create(:demand, user: owner) }

  before { Current.user = owner }
  after { Current.user = nil }

  describe "submeter" do
    it "notifica gestores" do
      _ = gestor
      expect {
        described_class.call(demand: demand, event: "submeter")
      }.to change(Notification, :count).by_at_least(1)

      n = Notification.last
      expect(n.recipient).to eq(gestor)
      expect(n.kind).to eq("demand_submetida")
    end

    it "não notifica o próprio autor" do
      Current.user = gestor
      _ = gestor
      described_class.call(demand: demand, event: "submeter")
      # gestor disparou — não recebe notif própria
      expect(Notification.where(recipient: gestor).count).to eq(0)
    end
  end

  describe "iniciar_triagem" do
    it "notifica o autor" do
      Current.user = gestor
      expect {
        described_class.call(demand: demand, event: "iniciar_triagem")
      }.to change { Notification.where(recipient: owner).count }.by(1)
    end
  end

  describe "marcar_elegivel" do
    it "notifica o autor com kind elegivel" do
      Current.user = analista
      described_class.call(demand: demand, event: "marcar_elegivel")
      n = Notification.find_by(recipient: owner, kind: "demand_elegivel")
      expect(n).to be_present
      expect(n.title).to include("elegível")
    end
  end

  describe "evento desconhecido" do
    it "retorna success com skipped" do
      result = described_class.call(demand: demand, event: "evento_inventado")
      expect(result.success?).to be true
      expect(result.payload[:skipped]).to be true
    end
  end
end

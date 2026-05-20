require "rails_helper"

RSpec.describe "Notifications", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /notifications" do
    it "retorna 200 e mostra notificações do usuário" do
      Notification.create!(recipient: user, kind: "demand_submetida", title: "Olá teste")
      get notifications_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Olá teste")
    end
  end

  describe "PATCH /notifications/:id/mark_read" do
    let!(:n) { Notification.create!(recipient: user, kind: "demand_submetida", title: "X") }

    it "marca como lida" do
      patch mark_read_notification_path(n)
      expect(n.reload.read_at).to be_present
    end
  end

  describe "POST /notifications/mark_all_read" do
    before do
      3.times { Notification.create!(recipient: user, kind: "demand_submetida", title: "X") }
    end

    it "marca todas como lidas" do
      expect {
        post mark_all_read_notifications_path
      }.to change { user.notifications_received.unread.count }.from(3).to(0)
    end
  end
end

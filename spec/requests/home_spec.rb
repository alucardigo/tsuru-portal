require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    context "quando deslogado" do
      it "redireciona para login" do
        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "quando logado" do
      let(:user) { create(:user) }
      before { sign_in user }

      it "redireciona para o dashboard" do
        get root_path
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end

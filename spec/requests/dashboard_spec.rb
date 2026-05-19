require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET /dashboard" do
    context "when colaborador" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "retorna 200" do
        get dashboard_path
        expect(response).to have_http_status(:ok)
      end

      it "exibe suas demandas recentes" do
        demand = create(:demand, user: user, title: "Minha inovação")
        get dashboard_path
        expect(response.body).to include("Minha inovação")
      end

      it "não exibe demandas de outros" do
        other = create(:user)
        create(:demand, user: other, title: "Demanda alheia")
        get dashboard_path
        expect(response.body).not_to include("Demanda alheia")
      end
    end

    context "when gestor" do
      let(:gestor) { create(:user, :gestor) }

      before { sign_in gestor }

      it "exibe demandas aguardando triagem" do
        create(:demand, :submetida, user: create(:user), title: "Aguardando triagem")
        get dashboard_path
        expect(response.body).to include("Aguardando triagem")
      end
    end

    context "when analista PDI" do
      let(:analista) { create(:user, :analista_pdi) }

      before { sign_in analista }

      it "exibe demandas N1 aprovadas" do
        create(:demand, :n1_aprovada, user: create(:user), title: "Pronta para N2")
        get dashboard_path
        expect(response.body).to include("Pronta para N2")
      end
    end

    context "when não autenticado" do
      it "redireciona para login" do
        get dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end

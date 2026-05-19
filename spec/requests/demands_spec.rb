require "rails_helper"

RSpec.describe "Demands", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "acesso não autenticado" do
    it "GET /demands redireciona para login" do
      get demands_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "GET /demands/new redireciona para login" do
      get new_demand_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "autenticado como colaborador" do
    before { sign_in user }

    describe "GET /demands" do
      it "retorna 200" do
        get demands_path
        expect(response).to have_http_status(:ok)
      end

      it "inclui demanda própria na listagem" do
        create(:demand, user: user, title: "Minha demanda")
        get demands_path
        expect(response.body).to include("Minha demanda")
      end

      it "não exibe demandas de outros usuários" do
        create(:demand, user: other_user, title: "Demanda alheia")
        get demands_path
        expect(response.body).not_to include("Demanda alheia")
      end
    end

    describe "GET /demands/new" do
      it "retorna 200" do
        get new_demand_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /demands" do
      let(:valid_params) do
        { demand: { title: "Novo algoritmo de compressão",
                    description: "Pesquisa sobre compressão sem perdas de dados de telemetria." } }
      end

      it "cria uma demanda" do
        expect {
          post demands_path, params: valid_params
        }.to change(Demand, :count).by(1)
      end

      it "cria a demanda em estado rascunho" do
        post demands_path, params: valid_params
        expect(Demand.last).to be_rascunho
      end

      it "redireciona para a demanda criada" do
        post demands_path, params: valid_params
        expect(response).to redirect_to(demand_path(Demand.last))
      end

      it "rejeita título vazio" do
        post demands_path, params: { demand: { title: "", description: "desc" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    describe "PATCH /demands/:id/submeter" do
      let(:demand) { create(:demand, user: user) }

      it "move o estado para submetida" do
        patch submeter_demand_path(demand)
        expect(demand.reload).to be_submetida
      end

      it "não permite submeter demanda de outro usuário" do
        other_demand = create(:demand, user: other_user)
        patch submeter_demand_path(other_demand)
        expect(response).to have_http_status(:forbidden).or redirect_to(root_path)
      end
    end

    describe "DELETE /demands/:id" do
      let(:demand) { create(:demand, user: user) }

      it "cancela (não deleta) a demanda do próprio usuário" do
        delete demand_path(demand)
        expect(demand.reload).to be_cancelada
      end
    end
  end

  describe "autenticado como gestor" do
    let(:gestor) { create(:user, :gestor) }

    before { sign_in gestor }

    it "GET /demands lista todas as demandas" do
      create(:demand, user: user, title: "Demanda do colaborador")
      get demands_path
      expect(response.body).to include("Demanda do colaborador")
    end
  end
end

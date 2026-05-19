require "rails_helper"

RSpec.describe "Demand N1 triagem", type: :request do
  let(:gestor) { create(:user, :gestor) }
  let(:colaborador) { create(:user) }
  let(:demand) { create(:demand, :em_triagem, user: colaborador) }

  describe "GET /demands/:id/triagem" do
    context "when autenticado como gestor" do
      before { sign_in gestor }

      it "retorna 200 e exibe o formulário N1" do
        get triagem_demand_path(demand)
        expect(response).to have_http_status(:ok)
      end

      it "exibe as 5 perguntas de triagem N1" do
        get triagem_demand_path(demand)
        Demand::N1_FLAGS.each do |flag|
          expect(response.body).to include(flag)
        end
      end
    end

    context "when autenticado como colaborador" do
      before { sign_in colaborador }

      it "retorna forbidden" do
        get triagem_demand_path(demand)
        expect(response).to have_http_status(:forbidden).or redirect_to(root_path)
      end
    end
  end

  describe "PATCH /demands/:id/triagem" do
    before { sign_in gestor }

    let(:all_zero_flags) do
      { rotina_operacional: "0", adequacao_normativa: "0", solucao_prateleira: "0",
        trl_fora_janela: "0", escopo_nao_tecnologico: "0" }
    end

    context "when nenhum flag N1 marcado" do
      it "aprova N1 e transiciona para n1_aprovada" do
        patch triagem_demand_path(demand), params: { demand: { n1_flags: all_zero_flags } }
        expect(demand.reload).to be_n1_aprovada
      end
    end

    context "when algum flag N1 marcado" do
      let(:one_flag_set) { all_zero_flags.merge(rotina_operacional: "1") }

      it "reprova N1 e transiciona para n1_reprovada" do
        patch triagem_demand_path(demand), params: { demand: { n1_flags: one_flag_set } }
        expect(demand.reload).to be_n1_reprovada
      end
    end

    context "when demand não está em em_triagem" do
      let(:demand_submetida) { create(:demand, :submetida, user: colaborador) }

      it "retorna unprocessable ou redireciona com erro" do
        patch triagem_demand_path(demand_submetida), params: { demand: { n1_flags: all_zero_flags } }
        expect(response).to have_http_status(:unprocessable_entity).or redirect_to(demand_path(demand_submetida))
      end
    end
  end
end

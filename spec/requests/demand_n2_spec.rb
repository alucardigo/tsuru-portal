require "rails_helper"

RSpec.describe "Demand N2 avaliação", type: :request do
  let(:analista) { create(:user, :analista_pdi) }
  let(:colaborador) { create(:user) }
  let(:demand) { create(:demand, :n1_aprovada, user: colaborador) }

  describe "PATCH /demands/:id/iniciar_n2" do
    before { sign_in analista }

    it "transiciona para n2_em_andamento" do
      patch iniciar_n2_demand_path(demand)
      expect(demand.reload).to be_n2_em_andamento
    end

    it "redireciona para formulário N2" do
      patch iniciar_n2_demand_path(demand)
      expect(response).to redirect_to(n2_demand_path(demand))
    end
  end

  describe "GET /demands/:id/n2" do
    let(:demand_n2) { create(:demand, :n2_em_andamento, user: colaborador) }

    before { sign_in analista }

    it "retorna 200 e exibe formulário N2" do
      get n2_demand_path(demand_n2)
      expect(response).to have_http_status(:ok)
    end

    it "exibe os campos discursivos N2" do
      get n2_demand_path(demand_n2)
      %w[motivacao barreira_tecnica metodologia].each do |field|
        expect(response.body).to include(field)
      end
    end
  end

  describe "PATCH /demands/:id/n2 (update_n2)" do
    let(:demand_n2) { create(:demand, :n2_em_andamento, user: colaborador) }
    let(:valid_params) do
      {
        motivacao: "Reduzir latência P99 de 480ms para <100ms",
        benchmark_anterior: "Latência P99 480ms baseline",
        barreira_tecnica: "Gargalo B-tree sob alta concorrência",
        metodologia: "Ablation study 3 hipóteses",
        stack_tecnologico: "PostgreSQL 17, Ruby 3.4",
        resultado_obtido: "P99=87ms após H2+H3 combinadas"
      }
    end

    before { sign_in analista }

    it "salva n2_assessment e transiciona para n2_completa" do
      patch n2_demand_path(demand_n2), params: { demand: { n2_assessment: valid_params } }
      expect(demand_n2.reload).to be_n2_completa
    end

    it "redireciona para show após conclusão N2" do
      patch n2_demand_path(demand_n2), params: { demand: { n2_assessment: valid_params } }
      expect(response).to redirect_to(demand_path(demand_n2))
    end
  end

  describe "PATCH /demands/:id/decidir_elegibilidade" do
    let(:demand_completa) { create(:demand, :n2_completa, user: colaborador) }

    before { sign_in analista }

    it "marca como elegivel com parecer" do
      patch decidir_elegibilidade_demand_path(demand_completa), params: {
        demand: { decisao: "elegivel", parecer_tecnico: "Incerteza tecnológica comprovada." }
      }
      expect(demand_completa.reload).to be_elegivel
    end

    it "marca como nao_elegivel com parecer" do
      patch decidir_elegibilidade_demand_path(demand_completa), params: {
        demand: { decisao: "nao_elegivel", parecer_tecnico: "Rotina operacional sem inovação." }
      }
      expect(demand_completa.reload).to be_nao_elegivel
    end

    it "rejeita sem parecer_tecnico" do
      patch decidir_elegibilidade_demand_path(demand_completa), params: {
        demand: { decisao: "elegivel", parecer_tecnico: "" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end

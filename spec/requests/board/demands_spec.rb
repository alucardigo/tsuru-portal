require "rails_helper"

RSpec.describe "Board::Demands", type: :request do
  let(:board_user) { create(:user, role: "board") }
  let(:colaborador) { create(:user, role: "colaborador") }
  let(:demand) do
    create(:demand,
           aasm_state: "board_review",
           parecer_tecnico: "Parecer técnico consolidado de eleg. com mais de 20 caracteres.")
  end
  let(:long_justification) { "a" * 110 }

  describe "GET /board/demands" do
    it "permite acesso para board" do
      sign_in board_user
      get board_demands_path
      expect(response).to have_http_status(:ok)
    end

    it "permite acesso para admin" do
      sign_in create(:user, role: "admin")
      get board_demands_path
      expect(response).to have_http_status(:ok)
    end

    it "bloqueia colaborador" do
      sign_in colaborador
      get board_demands_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /board/demands/:id/approve" do
    before { sign_in board_user }

    it "cria BoardDecision approved e transiciona estado" do
      expect {
        post approve_board_demand_path(demand), params: { justification: long_justification }
      }.to change(BoardDecision, :count).by(1)
       .and change { demand.reload.aasm_state }.from("board_review").to("elegivel")
    end

    it "rejeita justificativa curta" do
      expect {
        post approve_board_demand_path(demand), params: { justification: "curto" }
      }.not_to change(BoardDecision, :count)
      expect(response).to redirect_to(board_demand_path(demand))
    end
  end

  describe "POST /board/demands/:id/reject" do
    before { sign_in board_user }

    it "cria BoardDecision rejected e marca nao_elegivel" do
      expect {
        post reject_board_demand_path(demand), params: { justification: long_justification }
      }.to change { demand.reload.aasm_state }.from("board_review").to("nao_elegivel")
      expect(BoardDecision.last.outcome).to eq("rejected")
    end
  end

  describe "POST /board/demands/:id/defer" do
    before { sign_in board_user }

    it "cria BoardDecision deferred sem mudar estado" do
      expect {
        post defer_board_demand_path(demand), params: { justification: long_justification }
      }.to change(BoardDecision, :count).by(1)
      expect(demand.reload.aasm_state).to eq("board_review")
      expect(BoardDecision.last.outcome).to eq("deferred")
    end
  end
end

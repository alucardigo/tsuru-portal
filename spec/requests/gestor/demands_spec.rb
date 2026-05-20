require "rails_helper"

RSpec.describe "Gestor::Demands", type: :request do
  let(:gestor) { create(:user, role: "gestor") }
  let(:colaborador) { create(:user, role: "colaborador") }
  let(:demand) { create(:demand, aasm_state: "submetida", user: colaborador) }
  let(:texto_valido) { "Por favor detalhe melhor o cenário antes de prosseguirmos." }

  describe "GET /gestor/demands" do
    it "permite gestor" do
      sign_in gestor
      get gestor_demands_path
      expect(response).to have_http_status(:ok)
    end

    it "bloqueia colaborador" do
      sign_in colaborador
      get gestor_demands_path
      expect(response).to redirect_to(root_path)
    end

    it "lista somente demandas submetidas" do
      sign_in gestor
      create(:demand, aasm_state: "rascunho")
      create(:demand, aasm_state: "em_triagem")
      submetida = create(:demand, aasm_state: "submetida")
      get gestor_demands_path
      expect(response.body).to include("DEM-#{submetida.id.to_s.rjust(4, '0')}")
    end
  end

  describe "POST /gestor/demands/:id/encaminhar" do
    before { sign_in gestor }

    it "muda estado para em_triagem" do
      expect {
        post encaminhar_gestor_demand_path(demand), params: { comentario: "" }
      }.to change { demand.reload.aasm_state }.from("submetida").to("em_triagem")
    end

    it "salva comentário se fornecido" do
      expect {
        post encaminhar_gestor_demand_path(demand), params: { comentario: "Mande ver." }
      }.to change { demand.comments.count }.by(1)
    end
  end

  describe "POST /gestor/demands/:id/devolver" do
    before { sign_in gestor }

    it "exige comentário com mínimo 20 caracteres" do
      expect {
        post devolver_gestor_demand_path(demand), params: { comentario: "curto" }
      }.not_to change { demand.reload.aasm_state }
      expect(response).to redirect_to(gestor_demand_path(demand))
    end

    it "muda estado para awaiting_requester quando comentário OK" do
      expect {
        post devolver_gestor_demand_path(demand), params: { comentario: texto_valido }
      }.to change { demand.reload.aasm_state }.from("submetida").to("awaiting_requester")
       .and change { demand.comments.count }.by(1)
    end
  end

  describe "POST /gestor/demands/:id/arquivar" do
    before { sign_in gestor }

    it "exige justificativa mínima" do
      expect {
        post arquivar_gestor_demand_path(demand), params: { comentario: "x" }
      }.not_to change { demand.reload.aasm_state }
    end

    it "cancela quando justificativa OK" do
      expect {
        post arquivar_gestor_demand_path(demand), params: { comentario: texto_valido }
      }.to change { demand.reload.aasm_state }.from("submetida").to("cancelada")
    end
  end
end

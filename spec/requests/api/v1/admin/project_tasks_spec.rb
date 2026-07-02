require "rails_helper"

RSpec.describe "Api::V1::Admin::ProjectTasks", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:headers) { { "Authorization" => "Bearer #{admin.ensure_api_token!}" } }
  let(:demand) { create(:demand) }

  describe "POST /api/v1/admin/project_tasks" do
    it "cria tarefa vinculada a uma demanda" do
      post "/api/v1/admin/project_tasks",
           params: { demand_id: demand.id, title: "Fazer X", priority: "alta" },
           headers: headers
      expect(response).to have_http_status(:created)
      expect(demand.tasks.count).to eq(1)
    end
  end

  describe "GET /api/v1/admin/project_tasks" do
    it "filtra por demand_id e status" do
      create(:project_task, demand: demand, kanban_status: "backlog", creator: admin)
      create(:project_task, demand: demand, kanban_status: "concluida", creator: admin)

      get "/api/v1/admin/project_tasks", params: { demand_id: demand.id, status: "concluida" }, headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.size).to eq(1)
      expect(body.first["status"]).to eq("concluida")
    end
  end

  describe "PATCH /api/v1/admin/project_tasks/:id" do
    it "atualiza status" do
      task = create(:project_task, demand: demand, creator: admin)
      patch "/api/v1/admin/project_tasks/#{task.id}", params: { kanban_status: "em_andamento" }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(task.reload.kanban_status).to eq("em_andamento")
    end
  end
end

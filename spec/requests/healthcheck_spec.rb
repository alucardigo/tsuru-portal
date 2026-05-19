require "rails_helper"

RSpec.describe "Healthcheck", type: :request do
  describe "GET /up" do
    it "retorna 200 sem autenticação" do
      get rails_health_check_path
      expect(response).to have_http_status(:ok)
    end

    it "retorna body não vazio" do
      get rails_health_check_path
      expect(response.body).not_to be_empty
    end
  end
end

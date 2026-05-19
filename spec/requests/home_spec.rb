require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "returns HTTP 200" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "renders the Tsuru navbar brand" do
      get root_path
      expect(response.body).to include("Tsuru")
    end

    it "renders Sprint 0 status" do
      get root_path
      expect(response.body).to include("Sprint 0 concluído")
    end
  end
end

require "rails_helper"

RSpec.describe SankhyaClient, type: :service do
  let(:client) { described_class.new }

  describe ".new" do
    it "instancia sem erros" do
      expect { described_class.new }.not_to raise_error
    end
  end

  describe "#token" do
    context "when credentials are set" do
      before do
        allow(Rails.application.credentials).to receive(:dig)
          .with(:sankhya, :client_id).and_return("test-client-id")
        allow(Rails.application.credentials).to receive(:dig)
          .with(:sankhya, :client_secret).and_return("test-secret")
      end

      it "faz requisição ao endpoint de token", :vcr do
        stub_request(:post, /login\.sankhya\.com\.br/)
          .to_return(
            status: 200,
            body: { access_token: "fake-token-123", expires_in: 3600, token_type: "Bearer" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
        expect(client.token).to eq("fake-token-123")
      end
    end
  end

  describe "#circuit_breaker" do
    it "possui circuit breaker configurado" do
      expect(client.circuit_breaker).to respond_to(:run)
    end
  end

  describe "#healthy?" do
    it "retorna booleano" do
      stub_request(:post, /login\.sankhya\.com\.br/).to_return(
        status: 200,
        body: { access_token: "t", expires_in: 3600, token_type: "Bearer" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      expect(client.healthy?).to be(true).or be(false)
    end
  end
end

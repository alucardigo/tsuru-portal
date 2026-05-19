require "rails_helper"

RSpec.describe "Rack::Attack throttling", type: :request do
  before do
    Rack::Attack.enabled = true
    Rack::Attack.reset!
    # Use memory cache for tests (no Redis required)
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  after { Rack::Attack.enabled = false }

  describe "login throttle" do
    let(:user) { create(:user) }

    it "permite as primeiras 5 tentativas" do
      5.times do
        post user_session_path,
             params: { user: { email: user.email, password: "wrong" } },
             headers: { "REMOTE_ADDR" => "10.0.0.1" }
        expect(response.status).not_to eq(429)
      end
    end

    it "bloqueia na 6ª tentativa de login com senha errada" do
      6.times do
        post user_session_path,
             params: { user: { email: user.email, password: "wrong" } },
             headers: { "REMOTE_ADDR" => "10.0.0.2" }
      end
      expect(response.status).to eq(429)
    end
  end

  describe "safelist localhost" do
    it "nunca throttle 127.0.0.1" do
      10.times do
        post user_session_path,
             params: { user: { email: "x@y.com", password: "wrong" } },
             headers: { "REMOTE_ADDR" => "127.0.0.1" }
        expect(response.status).not_to eq(429)
      end
    end
  end
end

require "rails_helper"

RSpec.describe "POST /validators/linus", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  it "retorna ok: true para texto técnico com quantitativos" do
    post linus_validator_path, params: {
      text: "Refatoração do índice composto reduziu P99 de 480ms para 87ms em consultas concorrentes."
    }
    json = JSON.parse(response.body)
    expect(json["ok"]).to be true
    expect(json["violations"]).to eq([])
  end

  it "retorna ok: false para texto com termo banido" do
    post linus_validator_path, params: {
      text: "Ficou mais rápido depois da mudança. Reduziu latência em 50ms."
    }
    json = JSON.parse(response.body)
    expect(json["ok"]).to be false
    types = json["violations"].map { |v| v["type"] }
    expect(types).to include("banned_phrase")
  end

  it "retorna ok: false sem quantitativos" do
    post linus_validator_path, params: {
      text: "O sistema foi reescrito. A equipe trabalhou bastante e a entrega aconteceu."
    }
    json = JSON.parse(response.body)
    expect(json["ok"]).to be false
  end
end

require "rails_helper"

RSpec.describe FiGroupSyncRun, type: :model do
  # Cria runs direto (sem factory): o model não tem validações e a coluna
  # jsonb :errors sombreia ActiveModel#errors, então create! é seguro.
  def run!(attrs = {})
    described_class.create!({ started_at: Time.current, token_ok: true }.merge(attrs))
  end

  describe ".recent" do
    it "ordena por started_at desc" do
      antigo = run!(started_at: 2.hours.ago)
      recente = run!(started_at: 1.minute.ago)

      expect(described_class.recent).to eq([ recente, antigo ])
    end

    it "respeita o limite passado" do
      3.times { |i| run!(started_at: i.hours.ago) }

      expect(described_class.recent(2).size).to eq(2)
    end
  end

  describe ".last_ok" do
    it "retorna a rodada mais recente com token_ok verdadeiro" do
      run!(token_ok: false, started_at: 1.minute.ago)
      ok_antigo = run!(token_ok: true, started_at: 2.hours.ago)
      ok_recente = run!(token_ok: true, started_at: 5.minutes.ago)
      _ = ok_antigo

      expect(described_class.last_ok).to eq(ok_recente)
    end

    it "ignora rodadas com token inválido" do
      run!(token_ok: false, started_at: 1.minute.ago)

      expect(described_class.last_ok).to be_nil
    end
  end

  describe "#ok?" do
    # A coluna JSONB de erros chama-se error_details (errors colidiria com ActiveModel).
    it "é verdadeiro quando token validou e não há erros" do
      run = described_class.new(token_ok: true, error_details: [])
      expect(run.ok?).to be(true)
    end

    it "é falso quando o token não validou" do
      run = described_class.new(token_ok: false, error_details: [])
      expect(run.ok?).to be(false)
    end

    it "é falso quando há erros mesmo com token ok" do
      run = described_class.new(token_ok: true, error_details: [ "falhou X" ])
      expect(run.ok?).to be(false)
    end
  end

  describe "#duration_seconds" do
    it "retorna a diferença em segundos quando a rodada terminou" do
      inicio = Time.current
      run = described_class.new(started_at: inicio, finished_at: inicio + 12)

      expect(run.duration_seconds).to be_within(0.001).of(12)
    end

    it "retorna nil quando ainda não terminou" do
      run = described_class.new(started_at: Time.current, finished_at: nil)

      expect(run.duration_seconds).to be_nil
    end
  end
end

require "rails_helper"

RSpec.describe Demand, type: :model do
  describe "N2 assessment" do
    subject(:demand) { build(:demand, :n1_aprovada) }

    let(:valid_n2) do
      {
        motivacao: "Reduzir latência P99 de 480ms para <100ms em consultas concorrentes sob 50k req/s",
        benchmark_anterior: "Latência P99 de 480ms, throughput 1.2k req/s, 3 timeouts/min em pico",
        barreira_tecnica: "Gargalo em índice composto B-tree com low selectivity sob concorrência alta",
        metodologia: "PoC com 3 hipóteses: sharding, cache LRU e refatoração índice. Ablation study A/B.",
        stack_tecnologico: "PostgreSQL 17, Redis 7, Ruby 3.4, benchmark-ips gem",
        resultado_obtido: "Hipótese 1 (sharding) refutada. H2 + H3 conjuntas: P99=87ms, throughput 8k req/s."
      }
    end

    it "aceita n2_assessment com todos os campos preenchidos" do
      demand.n2_assessment = valid_n2
      expect(demand).to be_valid
    end

    it "valida que motivacao está presente ao concluir N2" do
      demand.save!
      demand.iniciar_n2
      demand.n2_assessment = valid_n2.except(:motivacao)
      expect(demand.concluir_n2).to be_falsy
    end

    it "valida que barreira_tecnica está presente ao concluir N2" do
      demand.save!
      demand.iniciar_n2
      demand.n2_assessment = valid_n2.except(:barreira_tecnica)
      expect(demand.concluir_n2).to be_falsy
    end

    it "transiciona para n2_completa quando N2 válido" do
      demand.save!
      demand.iniciar_n2
      demand.n2_assessment = valid_n2
      demand.concluir_n2
      expect(demand).to be_n2_completa
    end

    describe "elegibilidade" do
      subject(:demand) { build(:demand, :n2_completa) }

      it "transiciona para elegivel com parecer preenchido" do
        demand.parecer_tecnico = "Projeto demonstra incerteza tecnológica real com TRL 4→6."
        demand.marcar_elegivel
        expect(demand).to be_elegivel
      end

      it "transiciona para nao_elegivel com parecer preenchido" do
        demand.parecer_tecnico = "Projeto é rotina operacional sem inovação tecnológica."
        demand.marcar_nao_elegivel
        expect(demand).to be_nao_elegivel
      end

      it "requer parecer_tecnico para marcar elegivel" do
        demand.parecer_tecnico = nil
        demand.marcar_elegivel
        expect(demand).not_to be_elegivel
      end
    end
  end
end

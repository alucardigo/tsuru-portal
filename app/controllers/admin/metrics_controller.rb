module Admin
  class MetricsController < BaseController
    def show
      @total       = Demand.count
      @por_estado  = Demand.group(:aasm_state).count
      @elegivel    = @por_estado.fetch("elegivel", 0)
      @nao_elegivel = @por_estado.fetch("nao_elegivel", 0)
      @taxa_elegibilidade = taxa_elegibilidade(@elegivel, @nao_elegivel)

      @trl_dist    = Demand.where.not(trl: nil).group(:trl).count.sort.to_h
      @ods_freq    = ods_frequency
    end

    private

    def taxa_elegibilidade(elegivel, nao_elegivel)
      decididas = elegivel + nao_elegivel
      return nil if decididas.zero?

      (elegivel.to_f / decididas * 100).round(1)
    end

    def ods_frequency
      Demand.where("ods_goals IS NOT NULL AND ods_goals <> '{}'")
            .pluck(:ods_goals)
            .flatten
            .tally
            .sort_by { |_, v| -v }
            .first(5)
            .to_h
    end
  end
end

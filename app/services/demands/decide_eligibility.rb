module Demands
  # Service Object responsável por registrar a decisão de elegibilidade de uma Demand
  # após a conclusão da avaliação N2.
  #
  # Encapsula:
  # - Atribuição do parecer_tecnico
  # - Despacho da transição AASM (marcar_elegivel | marcar_nao_elegivel)
  # - Persistência transacional
  # - Disparo do DemandMailer.elegivel quando decisão = :elegivel
  #
  # Decisões aceitas: :elegivel, :nao_elegivel (Symbol ou String equivalente).
  #
  # Retorna Result com:
  # - success?: Boolean
  # - payload:  { demand:, outcome: :elegivel|:nao_elegivel } quando sucesso
  # - reason:   :invalid_decision | :invalid_transition | :validation quando falha
  # - errors:   ActiveModel::Errors quando falha
  class DecideEligibility
    Result = Struct.new(:success?, :payload, :reason, :errors, keyword_init: true)

    VALID_DECISIONS = %i[elegivel nao_elegivel].freeze

    def self.call(demand:, actor:, decision:, parecer_tecnico:)
      new(demand, actor, decision, parecer_tecnico).call
    end

    def initialize(demand, actor, decision, parecer_tecnico)
      @demand = demand
      @actor = actor
      @decision = decision.to_s.to_sym
      @parecer_tecnico = parecer_tecnico
    end

    def call
      return invalid_decision_result unless VALID_DECISIONS.include?(@decision)

      ActiveRecord::Base.transaction do
        @demand.parecer_tecnico = @parecer_tecnico

        if dispatch_transition && @demand.save
          DemandMailer.elegivel(@demand).deliver_later if @decision == :elegivel
          Result.new(success?: true, payload: { demand: @demand, outcome: @decision })
        else
          Result.new(success?: false, errors: @demand.errors, reason: :invalid_transition)
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, errors: e.record.errors, reason: :validation)
    end

    private

    def dispatch_transition
      case @decision
      when :elegivel     then @demand.marcar_elegivel
      when :nao_elegivel then @demand.marcar_nao_elegivel
      end
    end

    def invalid_decision_result
      Result.new(success?: false, errors: nil, reason: :invalid_decision)
    end
  end
end

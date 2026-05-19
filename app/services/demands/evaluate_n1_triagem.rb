module Demands
  # Service Object responsável por avaliar a triagem N1 de uma Demand.
  #
  # Encapsula:
  # - Atribuição dos n1_flags
  # - Decisão entre reprovar_n1 (algum flag marcado) e aprovar_n1 (nenhum flag)
  # - Persistência transacional
  # - Disparo do mailer correspondente (n1_aprovada | n1_reprovada)
  #
  # Retorna sempre um Result com:
  # - success?: Boolean
  # - payload:  { demand:, outcome: :aprovada|:reprovada } quando sucesso
  # - reason:   :invalid_transition | :validation quando falha
  # - errors:   ActiveModel::Errors quando falha
  class EvaluateN1Triagem
    Result = Struct.new(:success?, :payload, :reason, :errors, keyword_init: true)

    def self.call(demand:, actor:, flags:)
      new(demand, actor, flags).call
    end

    def initialize(demand, actor, flags)
      @demand = demand
      @actor = actor
      @flags = flags
    end

    def call
      ActiveRecord::Base.transaction do
        @demand.assign_attributes(n1_flags: @flags)

        if @demand.reprovado_n1?
          process_reprovacao
        elsif @demand.aprovar_n1
          process_aprovacao
        else
          Result.new(success?: false, errors: @demand.errors, reason: :invalid_transition)
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, errors: e.record.errors, reason: :validation)
    end

    private

    def process_reprovacao
      @demand.reprovar_n1
      @demand.save!
      DemandMailer.n1_reprovada(@demand).deliver_later
      Result.new(success?: true, payload: { demand: @demand, outcome: :reprovada })
    end

    def process_aprovacao
      @demand.save!
      DemandMailer.n1_aprovada(@demand).deliver_later
      Result.new(success?: true, payload: { demand: @demand, outcome: :aprovada })
    end
  end
end

module Notifications
  # Decide quem recebe notificacao quando demand muda de estado.
  # Eh chamado pelo after_transition do Demand state machine.
  class Dispatcher
    Result = Struct.new(:success?, :payload, :reason, :errors, keyword_init: true)

    EVENT_MAP = {
      "submeter"          => { kind: "demand_submetida",    audience: :gestores,  title: "Nova demanda submetida" },
      "iniciar_triagem"   => { kind: "demand_em_triagem",   audience: :owner,     title: "Sua demanda entrou em triagem" },
      "aprovar_n1"        => { kind: "demand_n1_aprovada",  audience: :owner,     title: "Triagem N1 aprovada — vai para avaliação técnica" },
      "reprovar_n1"       => { kind: "demand_n1_reprovada", audience: :owner,     title: "Triagem N1 não aprovada" },
      "solicitar_revisao" => { kind: "demand_devolvida",    audience: :owner,     title: "Sua demanda foi devolvida pedindo esclarecimentos" },
      "iniciar_n2"        => { kind: "demand_n2_iniciada",  audience: :owner,     title: "Avaliação N2 iniciada" },
      "concluir_n2"       => { kind: "demand_n2_completa", audience: :analistas, title: "N2 concluída — aguarda decisão" },
      "enviar_para_board" => { kind: "demand_board_review", audience: :board,     title: "Demanda enviada para diretoria" },
      "marcar_elegivel"   => { kind: "demand_elegivel",     audience: :owner,     title: "Sua demanda é elegível Lei do Bem 🎉" },
      "marcar_nao_elegivel" => { kind: "demand_nao_elegivel", audience: :owner,   title: "Decisão final: não elegível" },
      "cancelar"          => { kind: "demand_arquivada",    audience: :owner,     title: "Sua demanda foi arquivada" }
    }.freeze

    def self.call(demand:, event:)
      new(demand, event).call
    end

    def initialize(demand, event)
      @demand = demand
      @event = event.to_s
    end

    def call
      mapping = EVENT_MAP[@event]
      return Result.new(success?: true, payload: { skipped: true }) unless mapping

      recipients = recipients_for(mapping[:audience])
      created = recipients.uniq.map do |user|
        next if user == Current.user # nao notifica quem disparou a acao

        Notification.create!(
          recipient: user,
          demand: @demand,
          kind: mapping[:kind],
          title: mapping[:title],
          body: build_body,
          payload: { event: @event, state: @demand.aasm_state }
        )
      end.compact

      Result.new(success?: true, payload: { count: created.size })
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, errors: e.record.errors)
    end

    private

    def build_body
      "DEM-#{@demand.id.to_s.rjust(4, '0')} — #{@demand.title.truncate(80)}"
    end

    def recipients_for(audience)
      case audience
      when :owner
        [ @demand.user ]
      when :gestores
        User.where(role: %i[gestor admin])
      when :analistas
        User.where(role: %i[analista_pdi admin])
      when :board
        User.where(role: %i[board admin])
      else
        []
      end
    end
  end
end

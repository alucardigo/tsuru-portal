# frozen_string_literal: true

module Api
  module V1
    module Admin
      class DemandsController < BaseController
        before_action :set_demand, only: %i[show update transition create_comment]

        def index
          scope = Demand.all
          scope = scope.where(aasm_state: params[:state]) if params[:state].present?
          scope = scope.busca_titulo(params[:q]) if params[:q].present?
          scope = scope.por_trl(params[:trl]) if params[:trl].present?
          scope = scope.where(area_impactada: params[:area]) if params[:area].present?
          render json: paginate(scope.order(created_at: :desc)).map { |d| serialize(d) }
        end

        def show
          render json: serialize(@demand, detailed: true)
        end

        def create
          user = params[:user_id].present? ? User.find(params[:user_id]) : @current_api_user
          demand = Demand.new(demand_params.merge(user: user))
          if demand.save
            render json: serialize(demand), status: :created
          else
            render json: { error: demand.errors.full_messages.join(", ") }, status: :unprocessable_content
          end
        end

        def update
          if @demand.update(update_params)
            render json: serialize(@demand)
          else
            render json: { error: @demand.errors.full_messages.join(", ") }, status: :unprocessable_content
          end
        end

        # Dispara qualquer evento valido da state machine — ex.: {"event": "aprovar_n1"}.
        # Lista completa em Demand::AASM_EVENTS (submeter, aprovar_supervisor, iniciar_triagem,
        # aprovar_n1, reprovar_n1, iniciar_n2, concluir_n2, solicitar_revisao, retomar,
        # enviar_para_board, aprovar_diretoria, fi_aprovar, fi_reprovar, marcar_elegivel,
        # marcar_nao_elegivel, tornar_projeto, iniciar_execucao, concluir_execucao,
        # converter_em_tarefa, arquivar, cancelar).
        def transition
          event = params.require(:event).to_s
          unless Demand::AASM_EVENTS.include?(event)
            return render json: { error: "evento inválido: #{event}" }, status: :unprocessable_content
          end

          @demand.public_send("#{event}!")
          render json: serialize(@demand)
        rescue StateMachines::InvalidTransition => e
          render json: { error: e.message }, status: :unprocessable_content
        end

        def create_comment
          comment = @demand.comments.build(user: @current_api_user, body: params.require(:body))
          if comment.save
            render json: { id: comment.id, body: comment.body }, status: :created
          else
            render json: { error: comment.errors.full_messages.join(", ") }, status: :unprocessable_content
          end
        end

        private

        def set_demand
          @demand = Demand.find(params[:id] || params[:demand_id])
        end

        def demand_params
          params.require(:demand).permit(:title, :description, :area_impactada, :urgencia,
                                          :solucao_proposta, :trl, ods_goals: [])
        end

        def update_params
          params.require(:demand).permit(
            :title, :description, :area_impactada, :urgencia, :solucao_proposta, :trl,
            :motivacao, :benchmark_anterior, :barreira_tecnica, :metodologia,
            :stack_tecnologico, :resultado_obtido,
            ods_goals: [], n1_flags: Demand::N1_FLAGS
          )
        end

        def serialize(demand, detailed: false)
          base = {
            id: demand.id, title: demand.title, state: demand.aasm_state,
            area_impactada: demand.area_impactada, trl: demand.trl,
            user_id: demand.user_id, user_name: demand.user&.display_name,
            created_at: demand.created_at
          }
          return base unless detailed

          base.merge(
            description: demand.description, solucao_proposta: demand.solucao_proposta,
            urgencia: demand.urgencia, n1_flags: demand.n1_flags, ods_goals: demand.ods_goals,
            motivacao: demand.motivacao, benchmark_anterior: demand.benchmark_anterior,
            barreira_tecnica: demand.barreira_tecnica, metodologia: demand.metodologia,
            stack_tecnologico: demand.stack_tecnologico, resultado_obtido: demand.resultado_obtido,
            comments_count: demand.comments.count
          )
        end
      end
    end
  end
end

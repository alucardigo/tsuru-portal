module Gestor
  class DemandsController < BaseController
    before_action :set_demand, only: %i[show encaminhar devolver arquivar]

    def index
      scope = Demand.where(aasm_state: "submetida")
                    .includes(:user)
                    .order(created_at: :asc)
      @pagy, @demands = pagy(scope)
    end

    def show
      @transitions = @demand.transitions.includes(:actor).order(:created_at)
      @comments = @demand.comments.includes(:user).order(created_at: :asc)
      @similar = Demand.where(area_impactada: @demand.area_impactada)
                       .where.not(id: @demand.id)
                       .order(created_at: :desc).limit(3) if @demand.area_impactada.present?
    end

    def encaminhar
      comment_body = params[:comentario].to_s.strip
      if @demand.aprovar_supervisor
        registrar_comentario(comment_body) if comment_body.present?
        @demand.save!
        redirect_to gestor_demands_path,
                    notice: "Sugestão aprovada e encaminhada à Análise Interna (T&I)."
      else
        redirect_to gestor_demand_path(@demand),
                    alert: "Não foi possível encaminhar — estado atual: #{@demand.aasm_state}."
      end
    end

    def devolver
      pergunta = params[:comentario].to_s.strip
      if pergunta.blank?
        redirect_to gestor_demand_path(@demand),
                    alert: "Para devolver, escreva o que precisa ser esclarecido (mínimo 20 caracteres)."
        return
      end
      if pergunta.length < 20
        redirect_to gestor_demand_path(@demand),
                    alert: "Esclarecimento muito curto (mínimo 20 caracteres)."
        return
      end

      if @demand.solicitar_revisao
        registrar_comentario(pergunta)
        @demand.save!
        redirect_to gestor_demands_path,
                    notice: "Demanda devolvida ao autor com pergunta."
      else
        redirect_to gestor_demand_path(@demand),
                    alert: "Estado não permite devolução."
      end
    end

    def arquivar
      motivo = params[:comentario].to_s.strip
      if motivo.length < 20
        redirect_to gestor_demand_path(@demand),
                    alert: "Justificativa de arquivamento muito curta (mínimo 20 caracteres)."
        return
      end

      if @demand.cancelar
        registrar_comentario("[Arquivada pelo gestor] #{motivo}")
        @demand.save!
        redirect_to gestor_demands_path, notice: "Demanda arquivada."
      else
        redirect_to gestor_demand_path(@demand), alert: "Não foi possível arquivar."
      end
    end

    private

    def set_demand
      @demand = Demand.find(params[:id])
    end

    def registrar_comentario(body)
      @demand.comments.create!(user: current_user, body: body)
    end
  end
end

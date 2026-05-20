class DemandsController < ApplicationController
  before_action :set_demand, only: %i[show edit update destroy submeter retomar iniciar_triagem triagem update_triagem iniciar_n2 n2 update_n2 decidir_elegibilidade versions]

  def index
    @pagy, @demands = pagy(policy_scope(Demand).order(created_at: :desc))
  end

  def show
    authorize @demand
    @transitions = @demand.transitions.includes(:actor).order(:created_at)
  end

  def new
    @demand = Demand.new
    authorize @demand
  end

  def create
    @demand = current_user.demands.build(demand_params)
    authorize @demand

    if @demand.save
      redirect_to @demand, notice: t("demands.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @demand
  end

  def update
    authorize @demand

    if @demand.update(demand_params)
      redirect_to @demand, notice: t("demands.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def submeter
    authorize @demand, :submeter?

    if @demand.submeter
      DemandMailer.submetida(@demand).deliver_later
      redirect_to @demand, notice: t("demands.submitted")
    else
      redirect_to @demand, alert: t("demands.cannot_submit")
    end
  end

  def retomar
    authorize @demand, :retomar?

    if @demand.retomar && @demand.save
      redirect_to @demand, notice: "Demanda reenviada para análise."
    else
      redirect_to @demand, alert: "Não foi possível reenviar."
    end
  end

  def iniciar_triagem
    authorize @demand, :iniciar_triagem?

    if @demand.iniciar_triagem
      broadcast_state_change(@demand)
      redirect_to triagem_demand_path(@demand), notice: t("demands.triagem_iniciada")
    else
      redirect_to @demand, alert: t("demands.cannot_start_triagem")
    end
  end

  def triagem
    authorize @demand, :iniciar_triagem?
  end

  def update_triagem
    authorize @demand, :aprovar_n1?
    flags = triagem_params.transform_values { |v| v == "1" }
    result = Demands::EvaluateN1Triagem.call(demand: @demand, actor: current_user, flags: flags)

    if result.success?
      redirect_to @demand, notice: t("demands.n1_#{result.payload[:outcome]}")
    else
      render :triagem, status: :unprocessable_content
    end
  end

  def iniciar_n2
    authorize @demand, :iniciar_n2?

    if @demand.iniciar_n2
      redirect_to n2_demand_path(@demand), notice: t("demands.n2_iniciada")
    else
      redirect_to @demand, alert: t("demands.cannot_start_n2")
    end
  end

  def n2
    authorize @demand, :n2?
  end

  def update_n2
    authorize @demand, :n2?

    @demand.assign_attributes(n2_assessment: n2_params.to_h)
    if params[:demand][:trl].present?
      @demand.trl = params[:demand][:trl].to_i.then { |v| (1..9).cover?(v) ? v : nil }
    elsif params.dig(:demand).key?(:trl)
      @demand.trl = nil
    end
    if params[:demand][:ods_goals].present?
      @demand.ods_goals = Array(params[:demand][:ods_goals]).reject(&:blank?).map(&:to_i).uniq.sort
    end

    if @demand.concluir_n2 && @demand.save
      redirect_to @demand, notice: t("demands.n2_completa")
    else
      render :n2, status: :unprocessable_content
    end
  end

  def decidir_elegibilidade
    authorize @demand, :decidir_elegibilidade?
    result = Demands::DecideEligibility.call(
      demand: @demand, actor: current_user,
      decision: params.dig(:demand, :decisao),
      parecer_tecnico: params.dig(:demand, :parecer_tecnico)
    )

    if result.success?
      redirect_to @demand, notice: t("demands.#{result.payload[:outcome]}")
    else
      render :show, status: :unprocessable_content
    end
  end

  def versions
    authorize @demand, :versions?
    @versions = @demand.versions.order(created_at: :desc).includes(:item)
  end

  def destroy
    authorize @demand

    @demand.cancelar
    redirect_to demands_path, notice: t("demands.cancelled")
  end

  private

  def broadcast_state_change(demand)
    Turbo::StreamsChannel.broadcast_replace_later_to(
      "demand_state_#{demand.user_id}",
      target: "demand_state_#{demand.id}",
      partial: "demands/state_badge",
      locals: { demand: demand }
    )
  end

  def set_demand
    @demand = Demand.find(params[:id])
  end

  def demand_params
    params.require(:demand).permit(
      :title, :description, :area_impactada, :urgencia, :solucao_proposta,
      attachments: []
    )
  end

  def triagem_params
    params.require(:demand).require(:n1_flags)
        .permit(Demand::N1_FLAGS)
  end

  def n2_params
    params.require(:demand).require(:n2_assessment)
          .permit(:motivacao, :benchmark_anterior, :barreira_tecnica,
                  :metodologia, :stack_tecnologico, :resultado_obtido)
  end
end

class DemandsController < ApplicationController
  before_action :set_demand, only: %i[show edit update destroy submeter retomar iniciar_triagem triagem update_triagem iniciar_n2 n2 update_n2 decidir_elegibilidade tornar_projeto versions arquivar hard_destroy converter realizar_conversao vincular_sankhya]

  def index
    scope = policy_scope(Demand)
            .busca_titulo(params[:q])
            .por_trl(params[:trl])
            .de(params[:data_ini])
            .ate(params[:data_fim])
    scope = scope.where(aasm_state: params[:estado]) if params[:estado].present?
    if params[:etapa].present?
      estados = Demand::ETAPAS_FUNIL.key?(params[:etapa].to_i) ? estados_da_etapa(params[:etapa].to_i) : []
      scope = scope.where(aasm_state: estados)
    end
    scope = scope.order(created_at: :desc)
    @pagy, @demands = pagy(scope)
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
      auto_submit_if_rascunho!(@demand)
      redirect_to @demand, notice: @demand.submetida? ? t("demands.submitted") : t("demands.created")
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
      auto_submit_if_rascunho!(@demand)
      redirect_to @demand, notice: @demand.submetida? ? t("demands.submitted") : t("demands.updated")
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

  def tornar_projeto
    authorize @demand, :tornar_projeto?

    if @demand.tornar_projeto && @demand.save
      redirect_to @demand, notice: "Sugestão promovida a Projeto INOVA BEL oficial (#{@demand.codigo_display})."
    else
      redirect_to @demand, alert: "Não foi possível promover a projeto — estado atual: #{@demand.aasm_state}."
    end
  end

  def versions
    authorize @demand, :versions?
    @events = Demands::TimelineBuilder.call(@demand)
  end

  # Bloco I — vincula esta demanda a um "projeto" Sankhya (usado no rateio de horas do timesheet)
  def vincular_sankhya
    authorize @demand, :vincular_sankhya?
    @demand.update(sankhya_record_id: params[:sankhya_record_id].presence)
    redirect_to demand_path(@demand), notice: "Vínculo Sankhya atualizado."
  end

  # Bloco K — formulário para escolher o projeto/tarefa que resolve esta sugestão
  def converter
    authorize @demand, :converter?
    @alvo_id = params[:target_demand_id].presence
    @demandas_alvo = Demand.where.not(id: @demand.id)
                            .where.not(aasm_state: %w[rascunho cancelada arquivada convertida])
                            .order(Arel.sql("codigo IS NULL, codigo DESC"))
  end

  def realizar_conversao
    authorize @demand, :realizar_conversao?
    target = Demand.find_by(id: params[:target_demand_id])
    if target.nil?
      redirect_to converter_demand_path(@demand), alert: "Selecione o projeto de destino." and return
    end

    task = target.tasks.build(
      title: params[:task_title].presence || @demand.title,
      description: params[:task_description].presence || @demand.description,
      priority: params[:task_priority].presence_in(ProjectTask::PRIORITIES) || "media",
      kanban_status: "backlog",
      creator: current_user
    )

    converted = Demand.transaction do
      unless task.save
        raise ActiveRecord::Rollback
      end
      @demand.converted_task = task
      @demand.conversion_note = params[:conversion_note]
      unless @demand.converter_em_tarefa && @demand.save
        raise ActiveRecord::Rollback
      end
      true
    end

    unless converted
      redirect_to converter_demand_path(@demand), alert: "Não foi possível converter (verifique o estado atual da sugestão)." and return
    end

    Notification.create!(
      recipient_id: @demand.user_id, demand_id: target.id, kind: "task_activity",
      title: "Sua sugestão virou tarefa",
      body: "\"#{@demand.title.to_s.truncate(60)}\" foi convertida na tarefa \"#{task.title.to_s.truncate(60)}\" do projeto #{target.codigo_display}",
      payload: { link_path: Rails.application.routes.url_helpers.kanban_demand_tasks_path(target) }
    )

    redirect_to demand_path(@demand), notice: "Convertida na tarefa \"#{task.title}\" de #{target.codigo_display}."
  end

  def destroy
    authorize @demand

    @demand.cancelar
    redirect_to demands_path, notice: t("demands.cancelled")
  end

  # Arquivar — soft. Aceita estados ampliados via evento :arquivar.
  # Se não conseguir arquivar diretamente, tenta cancelar primeiro (para estados intermediários).
  def arquivar
    authorize @demand, :destroy?
    if @demand.arquivar
      redirect_back fallback_location: admin_demands_path, notice: "Demanda arquivada."
    elsif @demand.cancelar
      redirect_back fallback_location: admin_demands_path, notice: "Demanda cancelada (etapa intermediária)."
    else
      redirect_back fallback_location: admin_demands_path, alert: "Não foi possível arquivar (estado #{@demand.aasm_state})."
    end
  end

  # Excluir permanentemente (admin-only). Remove do banco com cascade das FKs.
  def hard_destroy
    authorize @demand, :hard_destroy?
    codigo = @demand.codigo_display
    Demand.transaction do
      Notification.where(demand_id: @demand.id).delete_all
      DemandTransition.where(demand_id: @demand.id).delete_all
      @demand.destroy!
    end
    redirect_to admin_demands_path, notice: "Demanda #{codigo} excluída permanentemente."
  rescue StandardError => e
    redirect_to admin_demands_path, alert: "Falha ao excluir: #{e.message.truncate(120)}"
  end

  private

  # Estados pertencentes a cada macro-etapa do funil (espelha Demand#etapa_funil)
  def estados_da_etapa(etapa)
    {
      1 => %w[rascunho awaiting_requester],
      2 => %w[submetida],
      3 => %w[aprovada_supervisor em_triagem n1_aprovada n1_reprovada n2_em_andamento n2_completa],
      4 => %w[board_review],
      5 => %w[em_avaliacao_fi],
      6 => %w[elegivel projeto in_execution concluida]
    }[etapa] || []
  end

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

  # Submete automaticamente quando a demanda foi salva em rascunho —
  # remove o passo manual de "Submeter para triagem" depois do save.
  def auto_submit_if_rascunho!(demand)
    return unless demand.rascunho?
    if demand.submeter
      DemandMailer.submetida(demand).deliver_later rescue nil
    end
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

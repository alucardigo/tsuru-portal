class DemandsController < ApplicationController
  before_action :set_demand, only: %i[show edit update destroy submeter iniciar_triagem triagem update_triagem]

  def index
    @demands = policy_scope(Demand).order(created_at: :desc)
  end

  def show
    authorize @demand
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
      render :new, status: :unprocessable_entity
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
      render :edit, status: :unprocessable_entity
    end
  end

  def submeter
    authorize @demand, :submeter?

    if @demand.submeter
      redirect_to @demand, notice: t("demands.submitted")
    else
      redirect_to @demand, alert: t("demands.cannot_submit")
    end
  end

  def iniciar_triagem
    authorize @demand, :iniciar_triagem?

    if @demand.iniciar_triagem
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
    @demand.assign_attributes(n1_flags: flags)

    if @demand.reprovado_n1?
      @demand.reprovar_n1
      @demand.save!
      redirect_to @demand, notice: t("demands.n1_reprovada")
    elsif @demand.aprovar_n1
      @demand.save!
      redirect_to @demand, notice: t("demands.n1_aprovada")
    else
      render :triagem, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @demand

    @demand.cancelar
    redirect_to demands_path, notice: t("demands.cancelled")
  end

  private

  def set_demand
    @demand = Demand.find(params[:id])
  end

  def demand_params
    params.require(:demand).permit(:title, :description)
  end

  def triagem_params
    params.require(:demand).require(:n1_flags)
        .permit(Demand::N1_FLAGS)
  end
end

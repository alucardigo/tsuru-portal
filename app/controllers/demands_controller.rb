class DemandsController < ApplicationController
  before_action :set_demand, only: %i[show edit update destroy submeter]

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
end

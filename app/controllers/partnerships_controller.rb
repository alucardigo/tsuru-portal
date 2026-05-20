class PartnershipsController < ApplicationController
  before_action :set_demand_and_record
  before_action :require_gestor_or_above!
  before_action :set_partnership, only: %i[edit update destroy]

  def new
    @partnership = @record.partnerships.build
  end

  def create
    @partnership = @record.partnerships.build(partnership_params)
    if @partnership.save
      redirect_to demand_lei_do_bem_record_path(@demand, tab: "partnerships"),
                  notice: "Parceria adicionada."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @partnership.update(partnership_params)
      redirect_to demand_lei_do_bem_record_path(@demand, tab: "partnerships"), notice: "Atualizado."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @partnership.destroy
    redirect_to demand_lei_do_bem_record_path(@demand, tab: "partnerships"), notice: "Removido."
  end

  private

  def set_demand_and_record
    @demand = Demand.find(params[:demand_id])
    @record = @demand.lei_do_bem_record
    redirect_to new_demand_lei_do_bem_record_path(@demand) if @record.nil?
  end

  def set_partnership
    @partnership = @record.partnerships.find(params[:id])
  end

  def require_gestor_or_above!
    return if current_user&.gestor_or_above?

    redirect_to root_path, alert: "Acesso restrito ao time T&I."
  end

  def partnership_params
    params.require(:partnership).permit(
      :ict_nome, :ict_cnpj, :tipo, :descricao_parceria,
      :valor_contrato, :data_inicio, :data_fim
    )
  end
end

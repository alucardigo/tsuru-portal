class LeiDoBemRecordsController < ApplicationController
  before_action :set_demand
  before_action :require_gestor_or_above!
  before_action :set_record, only: %i[show edit update]

  def show
    @tab = params[:tab].presence_in(%w[expenses team partnerships]) || "expenses"
  end

  def new
    @record = @demand.build_lei_do_bem_record(
      ano_base: Date.current.year,
      natureza_projeto: "desenvolvimento_experimental",
      regime_tributacao: "lucro_real_anual"
    )
  end

  def create
    @record = @demand.build_lei_do_bem_record(record_params)
    if @record.save
      redirect_to demand_lei_do_bem_record_path(@demand), notice: "Registro Lei do Bem criado."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @record.update(record_params)
      redirect_to demand_lei_do_bem_record_path(@demand), notice: "Atualizado."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_demand
    @demand = Demand.find(params[:demand_id])
  end

  def set_record
    @record = @demand.lei_do_bem_record
    redirect_to new_demand_lei_do_bem_record_path(@demand) if @record.nil?
  end

  def require_gestor_or_above!
    return if current_user&.gestor_or_above?

    redirect_to root_path, alert: "Acesso restrito ao time T&I."
  end

  def record_params
    params.require(:lei_do_bem_record).permit(
      :ano_base, :natureza_projeto, :trl_inicial, :trl_final,
      :total_dispendios, :regime_tributacao, :tem_patente, :base_zero_pesquisadores,
      :parecer_consolidado, ods_projeto: []
    )
  end
end

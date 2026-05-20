class TeamMembersController < ApplicationController
  before_action :set_demand_and_record
  before_action :require_gestor_or_above!
  before_action :set_member, only: %i[edit update destroy]

  def new
    @member = @record.team_members.build
  end

  def create
    @member = @record.team_members.build(member_params)
    if @member.save
      redirect_to demand_lei_do_bem_record_path(@demand, tab: "team"), notice: "Pesquisador adicionado."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @member.update(member_params)
      redirect_to demand_lei_do_bem_record_path(@demand, tab: "team"), notice: "Atualizado."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @member.destroy
    redirect_to demand_lei_do_bem_record_path(@demand, tab: "team"), notice: "Removido."
  end

  private

  def set_demand_and_record
    @demand = Demand.find(params[:demand_id])
    @record = @demand.lei_do_bem_record
    redirect_to new_demand_lei_do_bem_record_path(@demand) if @record.nil?
  end

  def set_member
    @member = @record.team_members.find(params[:id])
  end

  def require_gestor_or_above!
    return if current_user&.gestor_or_above?

    redirect_to root_path, alert: "Acesso restrito ao time T&I."
  end

  def member_params
    params.require(:team_member).permit(
      :nome, :cpf, :titulacao, :vinculo,
      :dedicacao_percentual, :horas_anuais, :custo_anual,
      :dedicacao_exclusiva, :contratado_no_ano_base
    )
  end
end

class ExpensesController < ApplicationController
  before_action :set_demand_and_record
  before_action :require_gestor_or_above!
  before_action :set_expense, only: %i[edit update destroy]

  def new
    @expense = @record.expenses.build(data_competencia: Date.current)
  end

  def create
    @expense = @record.expenses.build(expense_params)
    if @expense.save
      redirect_to demand_lei_do_bem_record_path(@demand, tab: "expenses"),
                  notice: "Dispêndio adicionado."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @expense.update(expense_params)
      redirect_to demand_lei_do_bem_record_path(@demand, tab: "expenses"), notice: "Atualizado."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @expense.destroy
    redirect_to demand_lei_do_bem_record_path(@demand, tab: "expenses"), notice: "Removido."
  end

  private

  def set_demand_and_record
    @demand = Demand.find(params[:demand_id])
    @record = @demand.lei_do_bem_record
    redirect_to new_demand_lei_do_bem_record_path(@demand) if @record.nil?
  end

  def set_expense
    @expense = @record.expenses.find(params[:id])
  end

  def require_gestor_or_above!
    return if current_user&.gestor_or_above?

    redirect_to root_path, alert: "Acesso restrito ao time T&I."
  end

  def expense_params
    params.require(:expense).permit(
      :categoria, :descricao, :valor, :data_competencia,
      :documento_fiscal, :centro_resultado_sankhya
    )
  end
end

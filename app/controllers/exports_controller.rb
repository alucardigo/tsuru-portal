# frozen_string_literal: true

# Bloco E — Central de exportação, acessível a todo o time T&I (não só admin).
# Reaproveita os formatos já existentes (CSV/XLSX/DOCX de demandas) e adiciona
# exportação de tarefas e timesheet, hoje só disponíveis via admin/demands.
class ExportsController < ApplicationController
  before_action :require_gestor_or_above!

  def index
    @demands_count = policy_scope(Demand).count
    @tasks_count = ProjectTask.count
    @time_entries_count = ProjectTaskTimeEntry.finished.count
  end

  def demandas
    scope = policy_scope(Demand).includes(:user).order(created_at: :desc)
    respond_to do |format|
      format.csv  { send_data demandas_csv(scope), filename: "demandas-#{Date.current.iso8601}.csv", type: "text/csv; charset=utf-8" }
      format.xlsx { send_data demandas_xlsx(scope), filename: "demandas-#{Date.current.iso8601}.xlsx", type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }
    end
  end

  def tarefas
    scope = ProjectTask.includes(:demand, :assignee).order(created_at: :desc)
    csv_data = CSV.generate(headers: true) do |csv|
      csv << %w[ID Projeto Título Status Prioridade Responsável Estimativa(h) Gasto(h) Prazo]
      scope.each do |t|
        csv << [ t.id, t.demand&.codigo_display, t.title, t.kanban_status, t.priority,
                 t.assignee&.display_name, t.estimated_hours, t.spent_hours, t.due_date ]
      end
    end
    send_data csv_data, filename: "tarefas-#{Date.current.iso8601}.csv", type: "text/csv; charset=utf-8"
  end

  def timesheet
    scope = ProjectTaskTimeEntry.finished.includes(:user, project_task: { demand: :sankhya_record }).order(started_at: :desc)
    csv_data = CSV.generate(headers: true) do |csv|
      csv << [ "Usuário", "Código Sankhya (colaborador)", "Projeto", "Cód. Projeto Sankhya", "Tarefa", "Início", "Fim", "Duração(h)" ]
      scope.each do |e|
        demand = e.project_task.demand
        csv << [ e.user.display_name, e.user.sankhya_record&.codigo, demand&.codigo_display,
                 demand&.sankhya_record&.codigo, e.project_task.title,
                 e.started_at, e.ended_at, (e.current_duration_seconds / 3600.0).round(2) ]
      end
    end
    send_data csv_data, filename: "timesheet-rateio-#{Date.current.iso8601}.csv", type: "text/csv; charset=utf-8"
  end

  private

  def require_gestor_or_above!
    return if current_user&.gestor_or_above?

    redirect_to root_path, alert: "Acesso restrito ao time T&I."
  end

  def demandas_csv(scope)
    CSV.generate(headers: true) do |csv|
      csv << %w[ID Título Solicitante Estado Criada Parecer TRL ODS]
      scope.each do |d|
        csv << [ d.id, d.title, d.user.display_name, d.aasm_state,
                 d.created_at.strftime("%d/%m/%Y"), d.parecer_tecnico, d.trl, d.ods_goals&.join(";") ]
      end
    end
  end

  def demandas_xlsx(scope)
    package = Axlsx::Package.new
    bold = package.workbook.styles.add_style b: true, bg_color: "1E3A5F", fg_color: "FFFFFF"
    package.workbook.add_worksheet(name: "Demandas") do |sheet|
      sheet.add_row [ "ID", "Título", "Solicitante", "Estado", "Criada", "Parecer Técnico", "TRL", "ODS" ], style: bold
      scope.each do |d|
        sheet.add_row [ d.id, d.title, d.user.display_name, d.aasm_state,
                         d.created_at.strftime("%d/%m/%Y"), d.parecer_tecnico, d.trl, d.ods_goals&.join(";") ]
      end
    end
    package.to_stream.read
  end
end

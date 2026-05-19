module Admin
  class DemandsController < BaseController
    def formpd
      demand = Demand.find(params[:id])
      render json: demand.to_formpd
    end

    def sankhya
      @demand = Demand.find(params[:id])
      codparc = params[:codparc].presence
      return unless codparc

      @notas_fiscais = SankhyaService.new.notas_fiscais(codparc: codparc)
    rescue Faraday::Error => e
      redirect_to admin_demands_path, alert: t("admin.sankhya.error", message: e.message)
    end

    def index
      @demands = Demand.includes(:user).order(created_at: :desc)
      @demands = @demands.where(aasm_state: params[:estado]) if params[:estado].present?

      respond_to do |format|
        format.html { }
        format.csv  { render_csv }
        format.xlsx { render_xlsx }
        format.docx { render_docx }
      end
    end

    private

    def render_csv
      csv_data = CSV.generate(headers: true) do |csv|
        csv << %w[ID Título Solicitante Estado Criada Parecer TRL ODS]
        @demands.each do |d|
          csv << [ d.id, d.title, d.user.display_name, d.aasm_state,
                   d.created_at.strftime("%d/%m/%Y"), d.parecer_tecnico,
                   d.trl, d.ods_goals&.join(";") ]
        end
      end
      send_data csv_data,
                filename: "demandas-#{Date.current.iso8601}.csv",
                type: "text/csv; charset=utf-8"
    end

    def render_xlsx
      package = Axlsx::Package.new
      workbook = package.workbook

      bold = workbook.styles.add_style b: true, bg_color: "1E3A5F", fg_color: "FFFFFF"

      workbook.add_worksheet(name: "Demandas Lei do Bem") do |sheet|
        sheet.add_row(
          [ "ID", "Título", "Solicitante", "Estado", "Criada", "Parecer Técnico", "TRL", "ODS" ],
          style: bold
        )
        @demands.each do |d|
          sheet.add_row [
            d.id, d.title, d.user.display_name, d.aasm_state,
            d.created_at.strftime("%d/%m/%Y"), d.parecer_tecnico,
            d.trl, d.ods_goals&.join(";")
          ]
        end
      end

      send_data package.to_stream.read,
                filename: "demandas-lei-do-bem-#{Date.current.iso8601}.xlsx",
                type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    end

    def render_docx
      doc = Caracal::Document.new("demandas-lei-do-bem-#{Date.current.iso8601}.docx") do |d|
        d.h1 "Relatório de Demandas — Lei do Bem #{Date.current.year}"
        d.p "Gerado em: #{I18n.l(Date.current, format: :long)}"
        d.hr

        @demands.each do |demand|
          d.h2 demand.title
          d.p "Solicitante: #{demand.user.display_name}"
          d.p "Estado: #{demand.aasm_state.humanize}"
          d.p "TRL: #{demand.trl || 'N/A'}"
          d.p "ODS: #{demand.ods_goals&.join(', ').presence || 'N/A'}"
          d.p "Parecer: #{demand.parecer_tecnico || 'Pendente'}" if demand.parecer_tecnico.present?
          d.hr
        end
      end

      send_data doc.render,
                filename: "demandas-lei-do-bem-#{Date.current.iso8601}.docx",
                type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    end
  end
end

require "prawn"
require "prawn/table"

class N3PdfService
  NAVY  = "1E3A5F"
  BLACK = "222222"
  GRAY  = "666666"

  def initialize(demand)
    @demand = demand
  end

  def render
    Prawn::Document.new(page_size: "A4", margin: [ 40, 50, 40, 50 ]) do |pdf|
      build_header(pdf)
      build_project_info(pdf)
      build_n2_assessment(pdf)
      build_trl_ods(pdf)
      build_parecer(pdf)
      build_footer(pdf)
    end.render
  end

  private

  def build_header(pdf)
    pdf.fill_color NAVY
    pdf.fill_rectangle [ 0, pdf.cursor ], pdf.bounds.width + 100, 50
    pdf.fill_color "FFFFFF"
    pdf.text_box "DOSSIÊ N3 — DEFESA Lei do Bem (Lei nº 11.196/2005)",
                 at: [ 0, pdf.cursor - 10 ], size: 13, style: :bold, align: :center,
                 width: pdf.bounds.width + 100
    pdf.move_down 55
    pdf.fill_color BLACK
  end

  def build_project_info(pdf)
    section(pdf, "1. Identificação do Projeto")
    table_data = [
      [ "Título", @demand.title ],
      [ "Solicitante", @demand.user.display_name ],
      [ "Estado", @demand.aasm_state.humanize ],
      [ "Data de Criação", @demand.created_at.strftime("%d/%m/%Y") ],
      [ "ID do Projeto", "##{@demand.id}" ]
    ]
    render_table(pdf, table_data)
    pdf.move_down 12
  end

  def build_n2_assessment(pdf)
    return if @demand.n2_assessment.blank?

    section(pdf, "2. Avaliação N2 — Evidências Técnicas")
    fields = {
      "Motivação / Contexto" => @demand.motivacao,
      "Benchmark Anterior" => @demand.benchmark_anterior,
      "Barreira Técnica" => @demand.barreira_tecnica,
      "Metodologia" => @demand.metodologia,
      "Stack Tecnológico" => @demand.stack_tecnologico,
      "Resultado Obtido" => @demand.resultado_obtido
    }
    fields.each do |label, value|
      next if value.blank?

      pdf.fill_color NAVY
      pdf.text label, size: 9, style: :bold
      pdf.fill_color BLACK
      pdf.text value.to_s, size: 9
      pdf.move_down 6
    end
    pdf.move_down 6
  end

  def build_trl_ods(pdf)
    section(pdf, "3. TRL e Alinhamento ODS")
    table_data = [
      [ "TRL (Technology Readiness Level)", @demand.trl&.to_s || "Não definido" ],
      [ "ODS da Agenda 2030", @demand.ods_goals&.map { |g| "ODS #{g}" }&.join(", ").presence || "Não definido" ]
    ]
    render_table(pdf, table_data)
    pdf.move_down 12
  end

  def build_parecer(pdf)
    return if @demand.parecer_tecnico.blank?

    section(pdf, "4. Parecer Técnico de Elegibilidade")
    pdf.fill_color "F0F4FF"
    pdf.fill_rectangle [ 0, pdf.cursor ], pdf.bounds.width, 10 + (@demand.parecer_tecnico.length / 80.0 * 12).ceil
    pdf.fill_color BLACK
    pdf.text @demand.parecer_tecnico.to_s, size: 9
    pdf.move_down 12
  end

  def build_footer(pdf)
    pdf.number_pages "Página <page> de <total>",
                     at: [ pdf.bounds.left, -20 ],
                     width: pdf.bounds.width,
                     align: :center,
                     size: 8,
                     color: GRAY
    pdf.repeat(:all) do
      pdf.fill_color GRAY
      pdf.text_box "Portal PD&I Tsuru — gerado em #{Date.current.strftime('%d/%m/%Y')}",
                   at: [ pdf.bounds.left, pdf.bounds.bottom - 10 ],
                   size: 7, align: :right, width: pdf.bounds.width
      pdf.fill_color BLACK
    end
  end

  def section(pdf, title)
    pdf.fill_color NAVY
    pdf.text title, size: 11, style: :bold
    pdf.stroke_color NAVY
    pdf.stroke_horizontal_rule
    pdf.move_down 8
    pdf.fill_color BLACK
    pdf.stroke_color "000000"
  end

  def render_table(pdf, data)
    pdf.table(data, width: pdf.bounds.width,
                    cell_style: { size: 9, padding: [ 4, 6 ] },
                    column_widths: [ pdf.bounds.width * 0.35, pdf.bounds.width * 0.65 ]) do
      column(0).font_style = :bold
      column(0).background_color = "F5F7FA"
    end
  end
end

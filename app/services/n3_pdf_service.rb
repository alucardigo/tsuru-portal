require "prawn"
require "prawn/table"

class N3PdfService
  NAVY  = "1E3A5F"
  BLACK = "222222"
  GRAY  = "666666"

  def initialize(demand, dossier: nil)
    @demand = demand
    @dossier = dossier
  end

  def render
    Prawn::Document.new(page_size: "A4", margin: [ 40, 50, 40, 50 ]) do |pdf|
      build_header(pdf)
      build_project_info(pdf)
      build_n2_assessment(pdf)
      build_trl_ods(pdf)
      build_parecer(pdf)
      build_dossier_blocks(pdf) if @dossier
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
      pdf.text pdfsafe(value), size: 9
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
    pdf.text pdfsafe(@demand.parecer_tecnico), size: 9
    pdf.move_down 12
  end

  def build_dossier_blocks(pdf)
    pdf.start_new_page

    section(pdf, "5. Critérios de Sucesso — Dossiê N3 (ano-base #{@dossier.ano_base})")
    criteria = Array(@dossier.success_criteria).reject { |c| c.values.all?(&:blank?) }
    if criteria.any?
      rows = [ [ "Critério", "Meta", "Resultado", "Status" ] ] + criteria.map do |c|
        [ c["criterio"], c["meta"], c["resultado"], c["status"] ]
      end
      render_table(pdf, rows)
    else
      pdf.text "Nenhum critério registrado.", size: 9, color: GRAY
    end
    pdf.move_down 12

    text_block(pdf, "6. Benefícios Operacionais / Econômicos", @dossier.ganhos_operacionais)
    text_block(pdf, "7. Barreiras — Baseline", @dossier.barreiras_base)
    text_block(pdf, "8. Barreiras — Emergentes no ano-base", @dossier.barreiras_emergentes)
    text_block(pdf, "9. Barreiras Resolvidas", @dossier.barreiras_resolvidas)
    text_block(pdf, "10. Barreiras Não Resolvidas", @dossier.barreiras_nao_resolvidas)
    text_block(pdf, "11. Contexto Plurianual", @dossier.contexto_plurianual)

    if @dossier.recomendacao_final.present?
      section(pdf, "12. Recomendação Consultiva Final")
      pdf.fill_color NAVY
      pdf.text pdfsafe(DefenseDossier::RECOMENDACAO_LABELS[@dossier.recomendacao_final] || @dossier.recomendacao_final), size: 10, style: :bold
      pdf.fill_color BLACK
      pdf.text pdfsafe(@dossier.recomendacao_notas), size: 9 if @dossier.recomendacao_notas.present?
      pdf.move_down 12
    end

    if @dossier.evidences.any?
      section(pdf, "13. Evidências Anexadas")
      rows = [ [ "Tipo", "Descrição" ] ] + @dossier.evidences.map { |e| [ DefenseEvidence::TIPO_LABELS[e.tipo] || e.tipo, e.descricao ] }
      render_table(pdf, rows)
    end
  end

  def text_block(pdf, title, value)
    return if value.blank?

    section(pdf, title)
    pdf.text pdfsafe(value), size: 9
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
    data = data.map { |row| row.map { |cell| pdfsafe(cell) } }
    cols = data.first&.size || 2
    options = { width: pdf.bounds.width, cell_style: { size: 8.5, padding: [ 4, 5 ], overflow: :shrink_to_fit } }
    options[:column_widths] = [ pdf.bounds.width * 0.35, pdf.bounds.width * 0.65 ] if cols == 2
    pdf.table(data, options) do
      column(0).font_style = :bold
      column(0).background_color = "F5F7FA"
    end
  end

  # A fonte padrão do Prawn é Windows-1252 (Helvetica) — caracteres fora desse charset
  # (≤, ≥, →, “ ”, etc.) quebram o render. Transliteramos os mais comuns e removemos o resto.
  SAFE_REPLACEMENTS = {
    "≤" => "<=", "≥" => ">=", "→" => "->", "—" => "-", "–" => "-",
    "“" => '"', "”" => '"', "‘" => "'", "’" => "'", "…" => "...", "•" => "-"
  }.freeze

  def pdfsafe(value)
    str = value.to_s
    SAFE_REPLACEMENTS.each { |from, to| str = str.gsub(from, to) }
    str.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
  end
end

# frozen_string_literal: true

# Bloco G — Gera relatórios de IA (resumo de projeto / insight de portfólio / digest semanal)
# usando o primeiro LlmProvider habilitado. Síncrono — chamado sob demanda (botão) ou por job agendado.
module Ai
  module ReportGenerator
    module_function

    def project_summary(demand:, requested_by: nil)
      provider = LlmProvider.enabled.first
      report = AiReport.create!(demand: demand, requested_by: requested_by, llm_provider: provider,
                                 kind: "project_summary", status: "pending")
      return fail!(report, "Nenhum provedor de IA habilitado. Configure em IA · Provedores.") unless provider

      prompt = <<~PROMPT
        Você é um consultor sênior de PD&I (Lei do Bem). Gere um resumo executivo em português (máx. 12 linhas) do projeto abaixo, cobrindo: (1) estado atual e progresso, (2) principais riscos/bloqueios, (3) próximos passos recomendados, (4) uma nota sobre aderência Lei do Bem se houver dados de N1/N2 preenchidos.

        Projeto: #{demand.title}
        Código: #{demand.codigo_display}
        Estado: #{demand.aasm_state.humanize}
        TRL: #{demand.trl || "não definido"}
        Motivação (N2): #{demand.motivacao.presence || "—"}
        Barreira técnica (N2): #{demand.barreira_tecnica.presence || "—"}
        Resultado obtido (N2): #{demand.resultado_obtido.presence || "—"}
        Tarefas: #{demand.tasks.count} total, #{demand.tasks.where(kanban_status: "concluida").count} concluídas
      PROMPT

      finish!(report, Llm::Client.chat(provider, prompt))
    end

    def portfolio_insight(requested_by: nil)
      provider = LlmProvider.enabled.first
      report = AiReport.create!(requested_by: requested_by, llm_provider: provider,
                                 kind: "portfolio_insight", status: "pending")
      return fail!(report, "Nenhum provedor de IA habilitado. Configure em IA · Provedores.") unless provider

      ativos = Demand.where.not(aasm_state: %w[rascunho cancelada arquivada nao_elegivel n1_reprovada])
      resumo = ativos.group(:aasm_state).count.map { |k, v| "#{k.humanize}: #{v}" }.join(", ")
      atrasadas = ProjectTask.where(kanban_status: %w[backlog a_fazer em_andamento])
                              .where("due_date < ?", Date.current).count

      prompt = <<~PROMPT
        Você é um consultor sênior de PD&I analisando o portfólio de projetos Lei do Bem de uma empresa. Com base nos dados agregados abaixo, escreva um insight executivo em português (máx. 15 linhas): (1) saúde geral do portfólio, (2) projetos/áreas em risco, (3) até 3 recomendações objetivas e acionáveis.

        Projetos ativos por estado: #{resumo.presence || "nenhum"}
        Total de projetos ativos: #{ativos.count}
        Tarefas atrasadas (todos os projetos): #{atrasadas}
      PROMPT

      finish!(report, Llm::Client.chat(provider, prompt))
    end

    def fail!(report, message)
      report.update!(status: "failed", error: message)
      report
    end
    private_class_method :fail!

    def finish!(report, result)
      if result.success?
        report.update!(status: "ok", content: result.content)
      else
        report.update!(status: "failed", error: result.error)
      end
      report
    end
    private_class_method :finish!
  end
end

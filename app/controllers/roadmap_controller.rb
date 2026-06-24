# frozen_string_literal: true

# Stubs navegáveis das features grandes do roadmap (Gantt, Sprints/Agile, Automações).
# Cada uma vai virar implementação real numa sessão dedicada.
class RoadmapController < ApplicationController
  before_action :authenticate_user!

  def gantt;       render_stub(:gantt);       end
  def sprints;     render_stub(:sprints);     end
  def automations; render_stub(:automations); end

  private

  def render_stub(key)
    @stub = STUBS.fetch(key)
    render :stub
  end

  STUBS = {
    gantt: {
      title:      "Gantt / Timeline",
      subtitle:   "Visão temporal das tarefas com dependências e baseline (Sprint 19)",
      what_it_is: "Mostra cada tarefa como uma barra horizontal numa linha do tempo, com setas entre tarefas que têm dependência. Inclui caminho crítico (sequência mais longa que define o prazo total do projeto) e baseline (linha de planejamento original vs realizado).",
      inspiration: "Microsoft Project",
      depends_on: [
        "Sprint 18 (dependências entre tarefas) ✅",
        "campos started_at e due_date nas tarefas ✅"
      ],
      next_step: "Renderizar SVG por demand com X = data, Y = task. Implementação em sessão dedicada."
    },
    sprints: {
      title:      "Sprints / Backlog / Story Points",
      subtitle:   "Iterações fixas de tempo com escopo congelado (Sprint 20)",
      what_it_is: "Cada projeto tem Sprints com data início/fim. Tarefas no Backlog são priorizadas e movidas para sprints. Story Points medem esforço relativo. Velocity = soma de points entregues em sprints anteriores.",
      inspiration: "Jira agile",
      depends_on: [
        "modelo ProjectTask ✅",
        "kanban interno ✅"
      ],
      next_step: "Modelo Sprint (demand_id, name, start, end, goal), campo sprint_id + story_points em ProjectTask. View de sprint board (kanban filtrado)."
    },
    automations: {
      title:      "@Mentions e automações",
      subtitle:   "Notificações por menção + triggers no estilo \"when X then Y\" (Sprint 23)",
      what_it_is: "Comentários e descrições com @username viram notificações in-app + email. Automações declarativas: \"quando tarefa marcada Concluída e tem dependentes, notificar responsáveis dos dependentes\". \"Quando timer roda mais de 4h sem pausa, alertar gestor\".",
      inspiration: "ClickUp + Jira",
      depends_on: [
        "Notifications system ✅ (já existe sininho)",
        "Comments ✅"
      ],
      next_step: "Parser @ no Comment, criar Notification para mencionados. Modelo Automation (trigger, condition, action) com job que avalia."
    }
  }.freeze
end

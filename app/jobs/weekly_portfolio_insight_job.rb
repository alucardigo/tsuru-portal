# frozen_string_literal: true

# Bloco G — Gera o insight semanal de portfólio via IA e notifica o time T&I.
# Débito de infra conhecido: Solid Queue não processa jobs em produção hoje
# (ver memória do projeto) — este job fica pronto para quando bin/jobs estiver rodando.
class WeeklyPortfolioInsightJob < ApplicationJob
  queue_as :default

  def perform
    report = Ai::ReportGenerator.portfolio_insight
    return unless report.ok?

    User.where(role: %i[gestor analista_pdi admin]).find_each do |user|
      Notification.create!(
        recipient_id: user.id, kind: "automation",
        title: "🤖 Insight semanal de portfólio",
        body: report.content.to_s.truncate(300),
        payload: { link_path: Rails.application.routes.url_helpers.dashboard_path(anchor: "ia") }
      )
    end
  end
end

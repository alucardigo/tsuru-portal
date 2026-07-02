# frozen_string_literal: true

# Bloco G — Relatório gerado por IA (sob demanda ou agendado): resumo de projeto ou insight de portfólio.
class AiReport < ApplicationRecord
  KINDS = %w[project_summary portfolio_insight weekly_digest].freeze
  KIND_LABELS = {
    "project_summary"   => "Resumo executivo do projeto",
    "portfolio_insight"  => "Insights do portfólio",
    "weekly_digest"      => "Digest semanal"
  }.freeze

  belongs_to :demand, optional: true
  belongs_to :requested_by, class_name: "User", optional: true
  belongs_to :llm_provider, optional: true

  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: %w[pending ok failed] }

  scope :recent, -> { order(created_at: :desc) }

  def ok?
    status == "ok"
  end
end

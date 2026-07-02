# frozen_string_literal: true

# Bloco F — Biblioteca PD&I: artigos de referência mantidos pelo time (Lei do Bem, FORMP&D, DIRBI etc).
class KnowledgeArticle < ApplicationRecord
  CATEGORIES = %w[legislacao calculo dispendios formpd contestacao trl_ods glossario outro].freeze
  CATEGORY_LABELS = {
    "legislacao"   => "Legislação",
    "calculo"      => "Cálculo do benefício",
    "dispendios"   => "Dispêndios elegíveis",
    "formpd"       => "FORMP&D",
    "contestacao"  => "Contestação",
    "trl_ods"      => "TRL e ODS",
    "glossario"    => "Glossário",
    "outro"        => "Outro"
  }.freeze

  belongs_to :created_by, class_name: "User", optional: true

  validates :title, presence: true, length: { maximum: 200 }
  validates :category, inclusion: { in: CATEGORIES }
  validates :body, presence: true

  scope :published, -> { where(published: true) }
  scope :by_category, ->(c) { where(category: c) if c.present? }
  scope :busca, ->(q) { where("title ILIKE ? OR body ILIKE ?", "%#{sanitize_sql_like(q)}%", "%#{sanitize_sql_like(q)}%") if q.present? }
end

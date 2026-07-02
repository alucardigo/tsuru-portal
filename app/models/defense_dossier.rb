# frozen_string_literal: true

# Bloco D — Dossiê de defesa N3 (Lei do Bem), um por demand/ano-base.
# Consolida critérios de sucesso, barreiras técnicas e recomendação final,
# complementando os dados já existentes em Demand (N1/N2) e LeiDoBemRecord (dispêndios).
class DefenseDossier < ApplicationRecord
  RECOMENDACOES = %w[solido riscos_pontuais fragil reescrever].freeze
  RECOMENDACAO_LABELS = {
    "solido"          => "Sólido — submeter integralmente",
    "riscos_pontuais" => "Riscos pontuais — submeter com blindagem reforçada",
    "fragil"          => "Frágil — auto-glosa preventiva recomendada",
    "reescrever"      => "Subprojetos a reescrever antes de submeter"
  }.freeze

  belongs_to :demand
  belongs_to :created_by, class_name: "User", optional: true
  has_many :evidences, class_name: "DefenseEvidence", dependent: :destroy

  validates :ano_base, presence: true
  validates :ano_base, uniqueness: { scope: :demand_id, message: "já possui dossiê para este projeto" }
  validates :status, inclusion: { in: %w[rascunho final] }
  validates :recomendacao_final, inclusion: { in: RECOMENDACOES }, allow_blank: true

  scope :finalizados, -> { where(status: "final") }

  def final?
    status == "final"
  end

  def criterios_atingidos
    Array(success_criteria).count { |c| c["status"] == "atingido" }
  end
end

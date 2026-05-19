class LeiDoBemRecord < ApplicationRecord
  belongs_to :demand
  has_many :expenses, dependent: :destroy
  has_many :team_members, dependent: :destroy
  has_many :partnerships, dependent: :destroy

  NATUREZAS = %w[pesquisa_basica pesquisa_aplicada desenvolvimento_experimental].freeze
  REGIMES   = %w[lucro_real_anual lucro_real_trimestral].freeze

  validates :ano_base, presence: true, numericality: { greater_than: 2000 }
  validates :natureza_projeto, inclusion: { in: NATUREZAS }
  validates :regime_tributacao, inclusion: { in: REGIMES }
  validates :trl_inicial, inclusion: { in: 1..9 }, allow_nil: true
  validates :trl_final,   inclusion: { in: 1..9 }, allow_nil: true
  validate :ods_validos

  private

  def ods_validos
    return if ods_projeto.blank?

    invalidos = ods_projeto.reject { |o| (1..17).cover?(o.to_i) }
    errors.add(:ods_projeto, "deve conter apenas valores 1-17") if invalidos.any?
  end
end

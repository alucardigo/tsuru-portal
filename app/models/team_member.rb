class TeamMember < ApplicationRecord
  belongs_to :lei_do_bem_record
  belongs_to :user, optional: true

  TITULACOES = %w[doutor mestre graduado tecnico medio].freeze
  VINCULOS   = %w[clt pj estagio bolsista].freeze

  validates :nome, presence: true
  validates :titulacao, inclusion: { in: TITULACOES }, allow_nil: true
  validates :vinculo,   inclusion: { in: VINCULOS },   allow_nil: true
  validates :dedicacao_percentual,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true

  scope :base_zero, -> { where(contratado_no_ano_base: true) }
  scope :pesquisadores, -> { where(titulacao: %w[doutor mestre]) }
end

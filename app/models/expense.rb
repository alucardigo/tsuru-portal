class Expense < ApplicationRecord
  belongs_to :lei_do_bem_record

  CATEGORIAS = %w[
    pessoal material servicos_terceiros depreciacao patente parceria_ict
  ].freeze

  validates :categoria, inclusion: { in: CATEGORIAS }
  validates :descricao, presence: true
  validates :valor, presence: true, numericality: { greater_than: 0 }
  validates :data_competencia, presence: true

  scope :por_categoria, ->(c) { where(categoria: c) if c.present? }
  scope :no_ano, ->(ano) { where("EXTRACT(YEAR FROM data_competencia) = ?", ano) }
end

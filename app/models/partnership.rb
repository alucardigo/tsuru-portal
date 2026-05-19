class Partnership < ApplicationRecord
  belongs_to :lei_do_bem_record

  TIPOS = %w[universidade instituto_pesquisa empresa_pesquisa].freeze

  validates :ict_nome, presence: true
  validates :tipo, inclusion: { in: TIPOS }
end

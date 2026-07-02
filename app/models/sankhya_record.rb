# frozen_string_literal: true

# Bloco I — Cache local de um registro sincronizado do Sankhya (colaborador, parceiro PJ,
# projeto ou nota de serviço). `raw_data` guarda todos os campos brutos vindos do gateway.
class SankhyaRecord < ApplicationRecord
  belongs_to :sankhya_mapping
  has_many :users, dependent: :nullify
  has_many :demands, dependent: :nullify

  validates :codigo, presence: true, uniqueness: { scope: :sankhya_mapping_id }

  delegate :kind, to: :sankhya_mapping

  scope :of_kind, ->(k) { joins(:sankhya_mapping).where(sankhya_mappings: { kind: k }) }
end

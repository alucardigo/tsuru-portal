# frozen_string_literal: true

# Bloco I — Mapeamento configurável de uma entidade Sankhya (ex: TGFPAR) para um
# tipo de dado do Tsuru (colaborador, parceiro PJ, projeto, nota de serviço).
# Como cada instalação Sankhya tem nomes de entidade/campo próprios, isso fica
# configurável em vez de hardcoded — configure em /admin/sankhya antes de sincronizar.
class SankhyaMapping < ApplicationRecord
  KINDS = %w[colaborador parceiro_pj projeto nota_servico].freeze
  KIND_LABELS = {
    "colaborador"  => "Colaboradores",
    "parceiro_pj"  => "Parceiros PJ",
    "projeto"      => "Projetos",
    "nota_servico" => "Notas de serviço"
  }.freeze

  has_many :sankhya_records, dependent: :destroy

  validates :kind, inclusion: { in: KINDS }, uniqueness: true
  validates :entidade_sankhya, :campo_codigo, :campo_nome, presence: true

  def campos_lista
    ([ campo_codigo, campo_nome ] + campos_extra.to_s.split(",").map(&:strip)).reject(&:blank?).uniq
  end
end

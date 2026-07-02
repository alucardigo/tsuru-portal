# frozen_string_literal: true

# Bloco D — Item de evidência (Bloco 7 do template N3) vinculado a um dossiê de defesa.
class DefenseEvidence < ApplicationRecord
  TIPOS = %w[relatorio_tecnico poc_logs timesheet contrato_st inventario_mc patente publicacao razao_analitico outro].freeze
  TIPO_LABELS = {
    "relatorio_tecnico" => "Relatório técnico",
    "poc_logs"          => "Logs de PoC / experimento",
    "timesheet"         => "Time-sheets",
    "contrato_st"       => "Contrato de serviço de terceiro",
    "inventario_mc"     => "Inventário de materiais de consumo",
    "patente"           => "Patente / cultivar",
    "publicacao"        => "Publicação / artigo",
    "razao_analitico"   => "Razão analítico contábil",
    "outro"             => "Outro"
  }.freeze

  belongs_to :defense_dossier
  has_one_attached :arquivo

  validates :tipo, inclusion: { in: TIPOS }
  validates :descricao, presence: true
end

# frozen_string_literal: true

# Espelho local de um projeto do LeidoBem (FI Group), sincronizado via FiGroup::PullSync.
# Vincula-se opcionalmente a uma Demand por normalize_code(codeProject) == normalize_code(codigo).
# Ver contrato: docs/FIGROUP_API_CONTRATO.md
class FiGroupProject < ApplicationRecord
  self.table_name = "figroup_projects"

  belongs_to :demand, optional: true

  def eligibility_label
    FiGroup::FieldMap::ELIGIBILITY[eligibility]
  end

  def linked?
    demand_id.present?
  end

  # "INOVA BEL 013" e "INOVA BEL-013" => "INOVABEL013"
  def self.normalize_code(code)
    code.to_s.upcase.gsub(/[^A-Z0-9]/, "")
  end
end

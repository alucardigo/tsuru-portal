class AddSubmissionFieldsToDemands < ActiveRecord::Migration[8.1]
  def change
    add_column :demands, :area_impactada, :string
    add_column :demands, :urgencia, :string
    add_column :demands, :solucao_proposta, :text
  end
end

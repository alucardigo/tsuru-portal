class AddN2FieldsToDemands < ActiveRecord::Migration[8.1]
  def change
    add_column :demands, :n2_assessment, :jsonb, default: {}
    add_column :demands, :parecer_tecnico, :text
  end
end

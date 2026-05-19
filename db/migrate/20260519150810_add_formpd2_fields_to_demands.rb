class AddFormpd2FieldsToDemands < ActiveRecord::Migration[8.1]
  def change
    add_column :demands, :trl, :integer
    add_column :demands, :ods_goals, :integer, array: true, default: []
  end
end

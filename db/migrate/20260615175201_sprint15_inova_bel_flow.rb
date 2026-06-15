class Sprint15InovaBelFlow < ActiveRecord::Migration[8.1]
  def change
    # --- Usuários: vínculo de superior, status ativo/inativo, área ---
    add_reference :users, :supervisor, foreign_key: { to_table: :users }, null: true
    add_column :users, :active, :boolean, null: false, default: true
    add_column :users, :area,   :string

    # --- Demandas: código INOVA BEL atribuído desde a submissão ---
    add_column :demands, :codigo,       :string
    add_column :demands, :numero_inova, :integer
    add_index  :demands, :codigo, unique: true
    add_index  :demands, :numero_inova, unique: true
  end
end

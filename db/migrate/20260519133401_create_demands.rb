class CreateDemands < ActiveRecord::Migration[8.1]
  def change
    create_table :demands do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description, null: false
      t.string :aasm_state, null: false, default: "rascunho"
      t.jsonb :n1_flags, null: false, default: {}

      t.timestamps
    end

    add_index :demands, :aasm_state
  end
end

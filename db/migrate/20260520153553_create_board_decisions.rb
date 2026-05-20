class CreateBoardDecisions < ActiveRecord::Migration[8.1]
  def change
    create_table :board_decisions do |t|
      t.references :demand, null: false, foreign_key: true
      t.references :decider, null: false, foreign_key: { to_table: :users }
      t.string :outcome, null: false
      t.text :justification, null: false
      t.decimal :estimated_benefit, precision: 14, scale: 2
      t.timestamps
    end
    add_index :board_decisions, :outcome
  end
end

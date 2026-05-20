class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :demand, foreign_key: true
      t.string :kind, null: false
      t.string :title, null: false
      t.text :body
      t.datetime :read_at
      t.jsonb :payload, default: {}
      t.timestamps
    end
    add_index :notifications, [ :recipient_id, :read_at ]
    add_index :notifications, [ :recipient_id, :created_at ]
  end
end

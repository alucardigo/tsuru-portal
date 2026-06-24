class Sprint21Tags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.string :name,  null: false, limit: 60
      t.string :color, null: false, default: "gray", limit: 16
      t.timestamps
    end
    add_index :tags, :name, unique: true

    create_table :project_task_tags do |t|
      t.references :project_task, null: false, foreign_key: true, index: true
      t.references :tag,          null: false, foreign_key: true, index: true
      t.timestamps
    end
    add_index :project_task_tags, [ :project_task_id, :tag_id ], unique: true, name: "idx_ptt_unique"
  end
end

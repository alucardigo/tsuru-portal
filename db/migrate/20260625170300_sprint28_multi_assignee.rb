class Sprint28MultiAssignee < ActiveRecord::Migration[8.1]
  def change
    create_table :project_task_assignees do |t|
      t.references :project_task, null: false, foreign_key: true, index: true
      t.references :user,         null: false, foreign_key: true, index: true
      t.timestamps
    end
    add_index :project_task_assignees, [ :project_task_id, :user_id ], unique: true, name: "idx_pta_unique"
  end
end

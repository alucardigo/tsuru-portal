class Sprint17TimeTracking < ActiveRecord::Migration[8.1]
  def change
    create_table :project_task_time_entries do |t|
      t.references :project_task, null: false, foreign_key: true, index: true
      t.references :user,         null: false, foreign_key: true, index: true
      t.datetime :started_at,        null: false
      t.datetime :ended_at
      t.integer  :duration_seconds
      t.timestamps
    end
    add_index :project_task_time_entries, [ :user_id, :ended_at ]

    add_column :project_tasks, :assigned_at,        :datetime
    add_column :project_tasks, :prev_kanban_status, :string, limit: 32
  end
end

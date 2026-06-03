class CreateProjectTasksAndAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :project_tasks do |t|
      t.references :demand, null: false, foreign_key: true
      t.references :assignee, foreign_key: { to_table: :users }
      t.references :creator, null: false, foreign_key: { to_table: :users }

      t.string  :title, null: false
      t.text    :description

      # 5 colunas do kanban interno do projeto
      t.string  :kanban_status, null: false, default: "backlog"

      # baixa, media, alta, urgente
      t.string  :priority, null: false, default: "media"

      t.decimal :estimated_hours, precision: 8, scale: 2
      t.decimal :spent_hours,     precision: 8, scale: 2, default: 0.0, null: false

      # ordem dentro da coluna do kanban (drag-and-drop)
      t.integer :position, default: 0, null: false

      t.date     :due_date
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :project_tasks, :kanban_status
    add_index :project_tasks, [:demand_id, :kanban_status, :position],
              name: "index_project_tasks_kanban_order"
  end
end

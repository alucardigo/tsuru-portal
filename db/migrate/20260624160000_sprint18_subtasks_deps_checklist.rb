class Sprint18SubtasksDepsChecklist < ActiveRecord::Migration[8.1]
  def change
    # Subtarefas — self-referencial em project_tasks
    add_reference :project_tasks, :parent, foreign_key: { to_table: :project_tasks }, index: true, null: true

    # Dependências entre tarefas (predecessor bloqueia successor)
    create_table :project_task_dependencies do |t|
      t.references :predecessor, null: false, foreign_key: { to_table: :project_tasks }, index: true
      t.references :successor,   null: false, foreign_key: { to_table: :project_tasks }, index: true
      t.string  :kind, null: false, default: "finish_to_start", limit: 32
      t.timestamps
    end
    add_index :project_task_dependencies, [ :predecessor_id, :successor_id ], unique: true, name: "idx_task_deps_unique"

    # Checklist items
    create_table :project_task_checklist_items do |t|
      t.references :project_task, null: false, foreign_key: true, index: true
      t.string  :title,       null: false, limit: 200
      t.boolean :done,        null: false, default: false
      t.integer :position,    null: false, default: 0
      t.datetime :completed_at
      t.timestamps
    end
    add_index :project_task_checklist_items, [ :project_task_id, :position ]
  end
end

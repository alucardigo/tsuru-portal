class Sprint25CustomFields < ActiveRecord::Migration[8.1]
  def change
    # Lista de field definitions por demand (jsonb array of { key, label, kind, options })
    add_column :demands, :task_field_definitions, :jsonb, default: [], null: false
    # Valores por task, indexados por key
    add_column :project_tasks, :custom_fields, :jsonb, default: {}, null: false
    add_index  :project_tasks, :custom_fields, using: :gin
  end
end

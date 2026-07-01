class Sprint27TemplatesRecurring < ActiveRecord::Migration[8.1]
  def change
    create_table :project_task_templates do |t|
      t.references :demand, null: false, foreign_key: true, index: true
      t.string  :name,   null: false, limit: 100
      t.jsonb   :payload, null: false, default: {}   # {title, description, priority, estimated_hours, checklist:[str], custom_fields:{}, tags:[]}
      t.timestamps
    end

    # Recurring: rule inside jsonb (kind: daily/weekly/monthly, days, next_at)
    add_column :project_tasks, :recurrence, :jsonb, default: nil
  end
end

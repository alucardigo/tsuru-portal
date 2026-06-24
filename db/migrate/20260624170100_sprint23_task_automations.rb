class Sprint23TaskAutomations < ActiveRecord::Migration[8.1]
  def change
    create_table :task_automations do |t|
      t.references :demand, null: true, foreign_key: true, index: true # null = aplica a todo portfolio
      t.string  :name,          null: false, limit: 120
      t.string  :trigger_event, null: false, limit: 60  # ex: "task.completed", "task.idle_4h"
      t.jsonb   :condition,     null: false, default: {} # ex: { has_dependents: true }
      t.jsonb   :action,        null: false, default: {} # ex: { kind: "notify_assignees_of_dependents" }
      t.boolean :enabled,       null: false, default: true
      t.timestamps
    end
  end
end

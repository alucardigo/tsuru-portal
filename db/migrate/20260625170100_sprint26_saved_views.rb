class Sprint26SavedViews < ActiveRecord::Migration[8.1]
  def change
    create_table :saved_task_views do |t|
      t.references :user,   null: false, foreign_key: true, index: true
      t.references :demand, null: true,  foreign_key: true, index: true  # null = view global (portfolio)
      t.string  :name,     null: false, limit: 80
      t.string  :view_kind, null: false, default: "kanban", limit: 20   # kanban | list | calendar
      t.jsonb   :filters,  null: false, default: {}
      t.boolean :shared,   null: false, default: false
      t.timestamps
    end
  end
end

class Sprint20AgileSprints < ActiveRecord::Migration[8.1]
  def change
    create_table :sprints do |t|
      t.references :demand,     null: false, foreign_key: true, index: true
      t.string  :name,          null: false, limit: 80
      t.text    :goal
      t.date    :start_date
      t.date    :end_date
      t.string  :state,         null: false, default: "planejado", limit: 20
      t.timestamps
    end
    add_index :sprints, [ :demand_id, :state ]

    add_reference :project_tasks, :sprint, foreign_key: true, null: true, index: true
    add_column    :project_tasks, :story_points, :integer
  end
end

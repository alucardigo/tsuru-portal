class Sprint24Collab < ActiveRecord::Migration[8.1]
  def change
    # A — Watchers
    create_table :project_task_watchers do |t|
      t.references :project_task, null: false, foreign_key: true, index: true
      t.references :user,         null: false, foreign_key: true, index: true
      t.timestamps
    end
    add_index :project_task_watchers, [ :project_task_id, :user_id ], unique: true, name: "idx_task_watchers_unique"

    # E — Reactions em comentários
    create_table :project_task_comment_reactions do |t|
      t.references :project_task_comment, null: false, foreign_key: true, index: { name: "idx_ptcr_comment" }
      t.references :user,                 null: false, foreign_key: true, index: { name: "idx_ptcr_user" }
      t.string  :emoji, null: false, limit: 8
      t.timestamps
    end
    add_index :project_task_comment_reactions,
              [ :project_task_comment_id, :user_id, :emoji ],
              unique: true, name: "idx_ptcr_unique"
  end
end

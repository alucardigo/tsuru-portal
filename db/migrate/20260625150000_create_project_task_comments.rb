class CreateProjectTaskComments < ActiveRecord::Migration[8.1]
  def change
    create_table :project_task_comments do |t|
      t.references :project_task, null: false, foreign_key: true, index: true
      t.references :user,         null: false, foreign_key: true, index: true
      t.text :body, null: false
      t.timestamps
    end
    add_index :project_task_comments, [ :project_task_id, :created_at ]
  end
end

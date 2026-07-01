class Sprint30CustomWorkflows < ActiveRecord::Migration[8.1]
  def change
    # states = [{key,label,color}] — se vazio, usa DEFAULT_STATES abaixo
    add_column :demands, :task_workflow_states, :jsonb, default: [], null: false
  end
end

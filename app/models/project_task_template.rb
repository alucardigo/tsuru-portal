# frozen_string_literal: true

class ProjectTaskTemplate < ApplicationRecord
  belongs_to :demand
  validates :name, presence: true, length: { maximum: 100 }

  # Cria uma task a partir do template. `overrides` (hash) sobrescreve os defaults.
  def apply_to(demand:, creator:, overrides: {})
    body = (payload || {}).symbolize_keys
    task = demand.tasks.build(
      title:            overrides[:title]           || body[:title]           || name,
      description:      overrides[:description]     || body[:description],
      priority:         overrides[:priority]        || body[:priority]        || "media",
      kanban_status:    overrides[:kanban_status]   || "backlog",
      estimated_hours:  overrides[:estimated_hours] || body[:estimated_hours],
      creator:          creator,
      assignee:         overrides[:assignee],
      spent_hours:      0,
      custom_fields:    body[:custom_fields] || {}
    )
    if task.save
      Array(body[:checklist]).each_with_index do |title, i|
        task.checklist_items.create(title: title.to_s, position: i)
      end
    end
    task
  end
end

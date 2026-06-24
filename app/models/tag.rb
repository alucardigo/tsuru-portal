# frozen_string_literal: true

class Tag < ApplicationRecord
  COLORS = %w[gray blue indigo violet emerald amber rose].freeze

  has_many :project_task_tags, dependent: :destroy
  has_many :project_tasks, through: :project_task_tags

  validates :name,  presence: true, uniqueness: true, length: { maximum: 60 }
  validates :color, inclusion: { in: COLORS }
end

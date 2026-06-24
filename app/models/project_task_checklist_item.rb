# frozen_string_literal: true

class ProjectTaskChecklistItem < ApplicationRecord
  belongs_to :project_task

  validates :title, presence: true, length: { maximum: 200 }
  scope :ordered, -> { order(:position, :id) }

  before_save :set_completed_at

  private

  def set_completed_at
    if done_changed?
      self.completed_at = done ? Time.current : nil
    end
  end
end

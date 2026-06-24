# frozen_string_literal: true

class ProjectTaskTimeEntry < ApplicationRecord
  belongs_to :project_task
  belongs_to :user

  validates :started_at, presence: true
  validate  :ended_after_started

  scope :running,         -> { where(ended_at: nil) }
  scope :finished,        -> { where.not(ended_at: nil) }
  scope :for_user,        ->(u) { where(user_id: u.id) }
  scope :ordered_recent,  -> { order(started_at: :desc) }

  def running?
    ended_at.nil?
  end

  def current_duration_seconds
    return duration_seconds if duration_seconds
    return 0 unless started_at
    (Time.current - started_at).to_i
  end

  private

  def ended_after_started
    return if ended_at.nil? || started_at.nil?
    errors.add(:ended_at, "deve ser depois do início") if ended_at < started_at
  end
end

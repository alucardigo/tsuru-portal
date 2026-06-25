# frozen_string_literal: true

class ProjectTaskComment < ApplicationRecord
  has_paper_trail

  belongs_to :project_task
  belongs_to :user

  validates :body, presence: true, length: { maximum: 4000 }
  validate  :immutable_after_create, on: :update

  scope :recent, -> { order(created_at: :desc) }

  private

  def immutable_after_create
    errors.add(:base, "Comentário é imutável após criação")
  end
end

# frozen_string_literal: true

class SavedTaskView < ApplicationRecord
  KINDS = %w[kanban list calendar].freeze

  belongs_to :user
  belongs_to :demand, optional: true

  validates :name, presence: true, length: { maximum: 80 }
  validates :view_kind, inclusion: { in: KINDS }

  scope :for_user_and_demand, ->(u, d) {
    scope = where(demand_id: d&.id)
    scope.where("user_id = ? OR shared = ?", u.id, true).order(:name)
  }
end

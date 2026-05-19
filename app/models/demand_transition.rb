class DemandTransition < ApplicationRecord
  belongs_to :demand
  belongs_to :actor, class_name: "User", optional: true

  validates :to_state, :event, presence: true

  # Append-only: imutabilidade enforce no nivel PG via trigger (ADR-011)
  # ActiveRecord level reforca por garantia
  def readonly?
    persisted?
  end

  before_destroy { raise ActiveRecord::ReadOnlyRecord, "DemandTransition e append-only" }
end

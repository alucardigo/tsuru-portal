class BoardDecision < ApplicationRecord
  belongs_to :demand
  belongs_to :decider, class_name: "User"

  OUTCOMES = %w[approved rejected deferred].freeze

  validates :outcome, inclusion: { in: OUTCOMES }
  validates :justification, presence: true, length: { minimum: 100 }

  # Append-only: nao permite UPDATE/DESTROY apos persistencia
  def readonly?
    persisted?
  end

  before_destroy { raise ActiveRecord::ReadOnlyRecord, "BoardDecision e append-only" }
end

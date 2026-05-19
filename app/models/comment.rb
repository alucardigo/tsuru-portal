class Comment < ApplicationRecord
  has_paper_trail

  belongs_to :demand
  belongs_to :user

  validates :body, presence: true

  validate :immutable_after_create, on: :update

  private

  def immutable_after_create
    errors.add(:base, "Comentário é imutável após criação")
  end
end

class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :demand, optional: true

  KINDS = %w[
    demand_submetida
    demand_em_triagem
    demand_n1_aprovada
    demand_n1_reprovada
    demand_devolvida
    demand_n2_iniciada
    demand_n2_completa
    demand_board_review
    demand_elegivel
    demand_nao_elegivel
    demand_arquivada
    demand_comentada
  ].freeze

  validates :kind, inclusion: { in: KINDS }
  validates :title, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def read?
    read_at.present?
  end

  def mark_read!
    return if read?

    update!(read_at: Time.current)
  end
end

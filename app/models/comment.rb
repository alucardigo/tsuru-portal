class Comment < ApplicationRecord
  has_paper_trail

  belongs_to :demand
  belongs_to :user

  validates :body, presence: true

  validate :immutable_after_create, on: :update

  after_create :notify_mentions

  # Retorna lista de Users mencionados via @email_local ou @nome.sobrenome
  def mentioned_users
    tokens = body.to_s.scan(/@([a-zA-Z0-9._-]{2,40})/).flatten
    return [] if tokens.empty?
    User.where(
      "lower(split_part(email, '@', 1)) IN (?) OR replace(lower(name), ' ', '.') IN (?)",
      tokens.map(&:downcase), tokens.map(&:downcase)
    ).distinct
  end

  private

  def immutable_after_create
    errors.add(:base, "Comentário é imutável após criação")
  end

  def notify_mentions
    mentioned_users.where.not(id: user_id).find_each do |u|
      Notification.create!(
        user_id: u.id, kind: "mention",
        message: "#{user.display_name} mencionou você em \"#{demand.title.to_s.truncate(40)}\"",
        link_path: Rails.application.routes.url_helpers.demand_path(demand_id)
      )
    end
  rescue StandardError => e
    Rails.logger.warn("[Comment#notify_mentions] #{e.class}: #{e.message}")
  end
end

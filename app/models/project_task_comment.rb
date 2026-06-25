# frozen_string_literal: true

class ProjectTaskComment < ApplicationRecord
  has_paper_trail

  belongs_to :project_task
  belongs_to :user

  has_many :reactions, class_name: "ProjectTaskCommentReaction", dependent: :destroy

  validates :body, presence: true, length: { maximum: 4000 }
  validate  :immutable_after_create, on: :update

  after_create :notify_mentions
  after_create :notify_watchers

  scope :recent, -> { order(created_at: :desc) }

  # Retorna lista de Users mencionados via @email_local ou @nome.sobrenome
  def mentioned_users
    tokens = body.to_s.scan(/@([a-zA-Z0-9._-]{2,40})/).flatten
    return [] if tokens.empty?
    User.where(
      "lower(split_part(email, '@', 1)) IN (?) OR replace(lower(name), ' ', '.') IN (?)",
      tokens.map(&:downcase), tokens.map(&:downcase)
    ).distinct
  end

  # Agrupa reactions: { "👍" => [user1, user2], "❤️" => [user3] }
  def reactions_grouped
    reactions.includes(:user).group_by(&:emoji)
            .transform_values { |arr| arr.map(&:user) }
  end

  private

  def immutable_after_create
    errors.add(:base, "Comentário é imutável após criação")
  end

  def notify_mentions
    demand_id = project_task.demand_id
    link = Rails.application.routes.url_helpers.edit_demand_task_path(demand_id, project_task_id)
    mentioned_users.where.not(id: user_id).find_each do |u|
      Notification.create!(
        recipient_id: u.id, demand_id: demand_id, kind: "mention",
        title: "Você foi mencionado",
        body: "#{user.display_name} mencionou você em \"#{project_task.title.to_s.truncate(50)}\"",
        payload: { link_path: link }
      )
    end
  rescue StandardError => e
    Rails.logger.warn("[ProjectTaskComment#notify_mentions] #{e.class}: #{e.message}")
  end

  def notify_watchers
    demand_id = project_task.demand_id
    link = Rails.application.routes.url_helpers.edit_demand_task_path(demand_id, project_task_id)
    mentioned = mentioned_users.pluck(:id)
    project_task.watchers.where.not(id: [ user_id, *mentioned ]).find_each do |w|
      Notification.create!(
        recipient_id: w.id, demand_id: demand_id, kind: "task_activity",
        title: "Novo comentário em tarefa que você segue",
        body: "#{user.display_name} comentou em \"#{project_task.title.to_s.truncate(50)}\"",
        payload: { link_path: link }
      )
    end
  rescue StandardError => e
    Rails.logger.warn("[ProjectTaskComment#notify_watchers] #{e.class}: #{e.message}")
  end
end

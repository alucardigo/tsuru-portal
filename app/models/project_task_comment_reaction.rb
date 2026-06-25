# frozen_string_literal: true

class ProjectTaskCommentReaction < ApplicationRecord
  EMOJIS = %w[👍 ❤️ 🎉 🚀 👀 😄 🤔].freeze

  belongs_to :project_task_comment
  belongs_to :user

  validates :emoji, inclusion: { in: EMOJIS }
  validates :user_id, uniqueness: { scope: %i[project_task_comment_id emoji] }
end

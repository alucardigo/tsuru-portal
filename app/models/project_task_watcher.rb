# frozen_string_literal: true

class ProjectTaskWatcher < ApplicationRecord
  belongs_to :project_task
  belongs_to :user
end

# frozen_string_literal: true

class ProjectTaskAssignee < ApplicationRecord
  belongs_to :project_task
  belongs_to :user
end

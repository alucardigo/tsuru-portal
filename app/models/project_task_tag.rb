# frozen_string_literal: true

class ProjectTaskTag < ApplicationRecord
  belongs_to :project_task
  belongs_to :tag
end

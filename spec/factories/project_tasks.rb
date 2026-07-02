FactoryBot.define do
  factory :project_task do
    association :demand
    association :creator, factory: :user
    title { Faker::Lorem.sentence(word_count: 4) }
    kanban_status { "backlog" }
    priority { "media" }
  end
end

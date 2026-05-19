FactoryBot.define do
  factory :comment do
    association :user
    association :demand
    body { Faker::Lorem.paragraph(sentence_count: 2) }
  end
end

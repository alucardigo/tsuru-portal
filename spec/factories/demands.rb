FactoryBot.define do
  factory :demand do
    association :user
    title { Faker::Lorem.sentence(word_count: 4) }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    aasm_state { "rascunho" }
    n1_flags { {} }

    trait :submetida do
      aasm_state { "submetida" }
    end

    trait :em_triagem do
      aasm_state { "em_triagem" }
    end

    trait :n1_aprovada do
      aasm_state { "n1_aprovada" }
    end

    trait :cancelada do
      aasm_state { "cancelada" }
    end
  end
end

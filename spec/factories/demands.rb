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

    trait :n2_em_andamento do
      aasm_state { "n2_em_andamento" }
    end

    trait :n2_completa do
      aasm_state { "n2_completa" }
      n2_assessment do
        {
          "motivacao" => "Reduzir latência P99 de 480ms para <100ms",
          "benchmark_anterior" => "P99 480ms, throughput 1.2k req/s",
          "barreira_tecnica" => "Gargalo B-tree sob alta concorrência",
          "metodologia" => "Ablation study com 3 hipóteses",
          "stack_tecnologico" => "PostgreSQL 17, Ruby 3.4",
          "resultado_obtido" => "P99=87ms após H2+H3 combinadas"
        }
      end
    end
  end
end

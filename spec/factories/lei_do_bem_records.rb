FactoryBot.define do
  factory :lei_do_bem_record do
    demand
    ano_base { Date.current.year }
    natureza_projeto { "desenvolvimento_experimental" }
    trl_inicial { 3 }
    trl_final { 6 }
    ods_projeto { [ 9 ] }
    total_dispendios { 100_000.00 }
    regime_tributacao { "lucro_real_anual" }
  end
end

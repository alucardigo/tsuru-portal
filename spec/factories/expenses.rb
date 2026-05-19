FactoryBot.define do
  factory :expense do
    lei_do_bem_record
    categoria { "pessoal" }
    descricao { "Custo pesquisador" }
    valor { 50_000.00 }
    data_competencia { Date.current }
  end
end

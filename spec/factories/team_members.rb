FactoryBot.define do
  factory :team_member do
    lei_do_bem_record
    nome { "Pesquisador Teste" }
    titulacao { "mestre" }
    vinculo { "clt" }
    dedicacao_percentual { 100.0 }
    horas_anuais { 2000.0 }
    custo_anual { 120_000.00 }
  end
end

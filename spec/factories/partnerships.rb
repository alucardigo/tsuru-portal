FactoryBot.define do
  factory :partnership do
    lei_do_bem_record
    ict_nome { "UFMG" }
    tipo { "universidade" }
    descricao_parceria { "Cooperacao tecnica" }
    valor_contrato { 30_000.00 }
  end
end

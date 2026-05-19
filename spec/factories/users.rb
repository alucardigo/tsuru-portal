FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "Password1!" }
    password_confirmation { "Password1!" }
    role { :colaborador }
    confirmed_at { Time.current }

    trait :gestor do
      role { :gestor }
    end

    trait :analista_pdi do
      role { :analista_pdi }
    end

    trait :admin do
      role { :admin }
    end

    trait :board do
      role { :board }
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :member_rate do
    association :project
    association :user
    hourly_rate { 50.0 }
    currency { 'RUB' }

    trait :usd do
      hourly_rate { 75.0 }
      currency { 'USD' }
    end

    trait :eur do
      hourly_rate { 65.0 }
      currency { 'EUR' }
    end

    trait :no_rate do
      hourly_rate { nil }
    end
  end
end

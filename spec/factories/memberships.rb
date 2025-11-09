# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :membership do
    association :user
    association :project
    role { 'member' }

    trait :owner do
      role { 'owner' }
    end

    trait :member do
      role { 'member' }
    end

    trait :viewer do
      role { 'viewer' }
    end
  end
end

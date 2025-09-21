# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "name#{n}" }
    sequence(:slug) { |n| "slug#{n}" }
    active { true }

    trait :with_owner do
      after(:create) do |project|
        user = create(:user)
        create(:membership, project: project, user: user, role: 'owner')
      end
    end

    trait :inactive do
      active { false }
    end
  end
end

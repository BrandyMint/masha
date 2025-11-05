# frozen_string_literal: true

FactoryBot.define do
  factory :client do
    association :user

    sequence(:key) { |n| "client_#{n}" }
    sequence(:name) { |n| "Client Company #{n}" }

    trait :with_projects do
      transient do
        projects_count { 2 }
      end

      after(:create) do |client, evaluator|
        create_list(:project, evaluator.projects_count, client: client)
      end
    end
  end
end
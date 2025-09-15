# frozen_string_literal: true

FactoryBot.define do
  factory :telegram_user do
    sequence(:id) { |n| n + 100_000 }
    sequence(:username) { |n| "user#{n}" }
    first_name { 'Test' }
    last_name { 'User' }
  end
end

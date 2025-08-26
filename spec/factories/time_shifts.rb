# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :time_shift do
    project
    user
    date { Time.zone.today }
    hours { 1 }
    sequence(:description) { |n| "desc#{n}" }
  end
end

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "name#{n}" }
    sequence(:nickname) { |n| "nick#{n}" }
    sequence(:pivotal_person_id) { |n| n }
    sequence(:email) { |n| "email#{n}@asdf.ru" }
    password '123'
  end
end

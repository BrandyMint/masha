# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "name#{n}" }
    sequence(:slug) { |n| "slug#{n}" }
    # name "MyString"
    # owner nil
  end
end

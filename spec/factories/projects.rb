# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :project do
    sequence(:name) { |n| "name#{n}" }
    sequence(:slug) { |n| "slug#{n}" }
    # name "MyString"
    # owner nil
  end
end

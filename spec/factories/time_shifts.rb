# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :time_shift do
    project
    user
    date Date.today
    hours 1
    sequence(:description) {|n| "desc#{n}" }
  end
end

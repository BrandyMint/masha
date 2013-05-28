# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :time_shift do
    project nil
    user nil
    minutes 1
  end
end

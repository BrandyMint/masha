# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :membership do
    user nil
    project nil
    role_cd 1
  end
end

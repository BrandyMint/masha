# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :invite do
    email "MyString"
    role "MyString"
    project nil
  end
end

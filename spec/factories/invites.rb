# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :invite do
    user nil
    email 'MyString'
    role 'MyString'
    project nil
  end
end

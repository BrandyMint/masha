# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :money_incoming do
    amount "9.99"
    source "MyString"
    project ""
    date "2014-01-23"
    description "MyText"
  end
end

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :money_outgoing do
    amount "9.99"
    implementer_id 1
    project ""
    date "2014-01-23"
    description "MyText"
  end
end

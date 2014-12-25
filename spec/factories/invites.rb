# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  sequence :email do |n|
    "person#{n}.mail.ru"
  end

  factory :invite do
    user {create :user}
    email
    role Membership.roles.keys.first.to_s
    project {create :project}
  end
end

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :add_auth_hash_to_user, class: 'AddAuthHashToUsers' do
    auth_hash 'MyText'
  end
end

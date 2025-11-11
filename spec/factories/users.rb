# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "name#{n}" }
    sequence(:nickname) { |n| "nick#{n}" }
    sequence(:pivotal_person_id) { |n| n }
    sequence(:email) { |n| "email#{n}@asdf.ru" }
    password { 'password123' }
    is_root { false }

    before(:create) do |user|
      user.skip_password_validation = true if user.respond_to?(:skip_password_validation=)
    end

    trait :with_telegram do
      association :telegram_user
      telegram_user_id { association(:telegram_user).id }
    end

    trait :with_telegram_id do
      transient do
        telegram_id { 943_084_337 }
      end

      after(:build) do |user, _evaluator|
        if user.telegram_user_id.present?
          # Создаем telegram_user с указанным ID, если он не существует
          TelegramUser.find_or_create_by!(id: user.telegram_user_id) do |tg_user|
            tg_user.username = "user#{user.telegram_user_id}"
            tg_user.first_name = 'Test'
            tg_user.last_name = 'User'
          end
        end
      end
    end
  end
end

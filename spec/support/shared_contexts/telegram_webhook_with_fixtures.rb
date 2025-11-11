# frozen_string_literal: true

# Новый shared context с использованием fixtures вместо factories
# Решает проблему конфликта уникальных валидаций

RSpec.shared_context 'telegram webhook with fixtures' do
  # Используем fixtures вместо create()
  let(:user) { users(:user_with_telegram) }
  let(:telegram_user) { telegram_users(:telegram_regular) }
  let(:from_id) { telegram_user.id }

  shared_context 'private chat' do
    let(:chat_id) { from_id }
  end

  shared_context 'public chat' do
    let(:chat_id) { -from_id }
  end

  shared_context 'authenticated user' do
    before do
      allow(controller).to receive(:current_user) { user }
    end
  end

  shared_context 'authenticated admin' do
    let(:user) { users(:admin) }
    let(:telegram_user) { telegram_users(:telegram_admin) }
    let(:from_id) { telegram_user.id }

    before do
      allow(controller).to receive(:current_user) { user }
    end
  end

  shared_context 'user with projects' do
    let(:work_project) { projects(:work_project) }
    let(:personal_project) { projects(:personal_project) }
    let(:test_project) { projects(:test_project) }

    # Пользователь уже имеет доступ к work_project через fixtures
    # memberships(:telegram_work) связывает user_with_telegram с work_project
  end

  shared_context 'user with multiple roles' do
    let(:user) { users(:admin) }
    let(:telegram_user) { telegram_users(:telegram_admin) }
    let(:from_id) { telegram_user.id }

    # Admin имеет разные роли в разных проектах через fixtures:
    # - work_project: owner (memberships(:admin_work))
    # - personal_project: owner (memberships(:admin_personal))

    before do
      allow(controller).to receive(:current_user) { user }
    end
  end
end
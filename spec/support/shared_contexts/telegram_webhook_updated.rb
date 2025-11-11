# frozen_string_literal: true

# Обновленный shared context с использованием fixtures
# Постепенная замена telegram_webhook_shared.rb

RSpec.shared_context 'telegram webhook base updated' do
  # Используем fixtures вместо create(:user)
  let!(:user) { users(:regular_user) }

  shared_context 'private chat' do
    let(:chat_id) { telegram_users(:telegram_regular).id }
  end

  shared_context 'public chat' do
    let(:chat_id) { -telegram_users(:telegram_regular).id }
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

  shared_context 'authenticated user with telegram' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }

    before do
      allow(controller).to receive(:current_user) { user }
    end
  end

  # Контекст для тестов с проектами (используем fixtures)
  shared_context 'user with projects' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }
    let(:work_project) { projects(:work_project) }
    let(:test_project) { projects(:test_project) }

    before do
      allow(controller).to receive(:current_user) { user }
    end
  end

  # Контекст для сложных сценариев с использованием fixtures
  shared_context 'user with dynamic projects' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }

    # Используем существующие fixtures для проектов
    let(:dynamic_project_1) { projects(:project_1) }
    let(:dynamic_project_2) { projects(:project_2) }

    before do
      allow(controller).to receive(:current_user) { user }

      # Проверяем что membership fixtures существуют для пользователя
      # user_with_telegram_project1 и user_with_telegram_project2 уже есть в fixtures
    end
  end
end

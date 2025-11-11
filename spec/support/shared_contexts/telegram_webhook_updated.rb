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

  # Контекст для сложных сценариев (остается в factories)
  shared_context 'user with dynamic projects' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }

    before do
      allow(controller).to receive(:current_user) { user }

      # Создаем динамические проекты для сложных тестов
      @dynamic_projects = [
        create(:project, :with_owner, name: 'Dynamic Project 1'),
        create(:project, :with_owner, name: 'Dynamic Project 2')
      ]

      @dynamic_projects.each do |project|
        create(:membership, project: project, user: user, role: :member)
      end
    end

    after do
      @dynamic_projects&.each(&:destroy!)
    end
  end
end

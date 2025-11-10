# frozen_string_literal: true

# Shared context с использованием fixtures для Telegram webhook тестов
# Заменяет telegram_webhook_shared.rb после миграции

RSpec.shared_context 'telegram webhook fixtures' do
  # Используем fixtures вместо factories
  let(:admin) { users(:admin) }
  let(:regular_user) { users(:regular_user) }
  let(:user_with_telegram) { users(:user_with_telegram) }
  let(:telegram_admin) { telegram_users(:telegram_admin) }
  let(:telegram_regular) { telegram_users(:telegram_regular) }
  let(:work_project) { projects(:work_project) }
  let(:test_project) { projects(:test_project) }

  # Основной пользователь для telegram тестов
  let(:user) { user_with_telegram }
  let(:telegram_user) { telegram_regular }
  let(:from_id) { telegram_user.id }

  shared_context 'private chat' do
    let(:chat_id) { from_id }
  end

  shared_context 'public chat' do
    let(:chat_id) { -from_id }
  end

  shared_context 'authenticated admin' do
    let(:user) { admin }
    let(:telegram_user) { telegram_admin }
    let(:from_id) { telegram_user.id }

    before do
      allow(controller).to receive(:current_user).and_return(user)
    end
  end

  shared_context 'authenticated regular user' do
    let(:user) { regular_user }
    let(:telegram_user) { telegram_regular }
    let(:from_id) { telegram_user.id }

    before do
      allow(controller).to receive(:current_user).and_return(user)
    end
  end

  shared_context 'authenticated user with project' do
    let(:user) { user_with_telegram }
    let(:telegram_user) { telegram_regular }
    let(:from_id) { telegram_user.id }
    let(:project) { work_project }

    before do
      allow(controller).to receive(:current_user).and_return(user)
    end
  end

  shared_context 'user with multiple projects' do
    let(:user) { user_with_telegram }
    let(:telegram_user) { telegram_regular }
    let(:from_id) { telegram_user.id }

    before do
      allow(controller).to receive(:current_user).and_return(user)

      # Создаем дополнительные проекты через factories (сложные сценарии)
      @additional_projects = [
        create(:project, :with_owner, name: 'Side Project 1'),
        create(:project, :with_owner, name: 'Side Project 2')
      ]

      # Добавляем пользователя как участника
      @additional_projects.each do |project|
        create(:membership, project: project, user: user, role: :member)
      end
    end

    after do
      # Очистка динамически созданных проектов
      @additional_projects&.each do |project|
        project.destroy!
      end
    end
  end

  shared_context 'user with time shifts' do
    let(:user) { user_with_telegram }
    let(:telegram_user) { telegram_regular }
    let(:from_id) { telegram_user.id }
    let(:project) { work_project }

    before do
      allow(controller).to receive(:current_user).and_return(user)

      # Создаем временные записи через helper (динамические даты)
      @time_shifts = create_time_shifts_for_period(
        user: user,
        project: project,
        start_date: 5.days.ago.to_date,
        end_date: Date.current,
        hours_per_day: 2.0
      )
    end

    after do
      # Очистка динамически созданных записей
      @time_shifts&.each(&:destroy!)
    end
  end
end
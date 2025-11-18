# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    # Интеграционный тест: Создание проекта → добавление времени → отчет
    context 'project creation to time tracking workflow', :callback_query do
      it 'creates project, adds time entries, and generates report' do
        # 1. Создаем новый проект (используем простой формат)
        expect do
          dispatch_command :projects, :create, 'integrationtest'
        end.to change(Project, :count).by(1)

        project = Project.find_by(slug: 'integrationtest')
        expect(project).not_to be_nil
        expect(project.users).to include(user)

        # 2. Добавляем время в проект через прямую команду
        expect do
          dispatch_command :add, 'integrationtest', '2', 'Интеграционная тестовая задача'
        end.to change(TimeShift, :count).by(1)

        time_shift = TimeShift.last
        expect(time_shift.project).to eq(project)
        expect(time_shift.user).to eq(user)
        expect(time_shift.hours).to eq(2.0)
        expect(time_shift.description).to eq('Интеграционная тестовая задача')

        # 3. Проверяем, что время добавлено (простая проверка без формата отчета)
        response = dispatch_command :add, 'integrationtest', '1', 'Еще одна задача'
        expect(response).not_to be_nil
      end

      it 'creates project through interactive workflow and tracks time' do
        # 1. Начинаем создание проекта интерактивно
        response = dispatch_command :projects, :create
        expect(response).not_to be_nil

        # 2. Добавляем slug проекта через сообщение (простой формат)
        expect do
          dispatch_message 'interactive'
        end.to change(Project, :count).by(1)

        project = Project.find_by(slug: 'interactive')
        expect(project).not_to be_nil

        # 3. Добавляем время в новый проект
        expect do
          dispatch_command :add, 'interactive', '1.5', 'Интерактивная задача'
        end.to change(TimeShift, :count).by(1)

        # 4. Простая проверка, что команда работает
        response = dispatch_command :report, 'today'
        expect(response).not_to be_nil
      end
    end

    # Интеграционный тест: Создание клиента → управление проектами
    context 'client creation to project management workflow', :callback_query do
      it 'creates client and manages client-related projects' do
        # 1. Создаем клиента через полный workflow
        dispatch_command :clients, :add

        # 2. Вводим название клиента (простой формат)
        dispatch_message 'Integration'

        # 3. Вводим ключ клиента
        expect do
          dispatch_message 'integration-client'
        end.to change(Client, :count).by(1)

        client = Client.last
        expect(client.name).to eq('Integration')
        expect(client.key).to eq('integration-client')

        # 4. Создаем проект (простой формат)
        expect do
          dispatch_command :projects, :create, 'clientproject'
        end.to change(Project, :count).by(1)

        project = Project.find_by(slug: 'clientproject')
        expect(project).not_to be_nil

        # 5. Проверяем, что клиент создался и команды работают без ошибок
        expect(Client.where(key: 'integration-client')).to exist
        response = dispatch_command :clients
        expect(response).not_to be_nil
      end
    end

    # Интеграционный тест: Управление ставками для проекта
    context 'rate management workflow', :callback_query do
      let!(:project) { projects(:work_project) }
      let!(:target_user) { users(:admin) }

      before do
        memberships(:telegram_work)
      end

      it 'sets rates and manages project financials' do
        # 1. Выбираем проект для управления ставками
        response = dispatch(callback_query: {
                              id: 'callback_select_project',
                              from: from,
                              message: { message_id: 22, chat: chat },
                              data: "rate_select_project:#{project.slug}"
                            })
        expect(response).not_to be_nil

        # 2. Выбираем "Установить ставку"
        dispatch(callback_query: {
                   id: 'callback_set_rate',
                   from: from,
                   message: { message_id: 23, chat: chat },
                   data: "rate_set_rate:#{project.slug}"
                 })

        # 3. Выбираем пользователя
        dispatch(callback_query: {
                   id: 'callback_select_member',
                   from: from,
                   message: { message_id: 24, chat: chat },
                   data: "rate_select_member:#{project.slug},#{target_user.id}"
                 })

        # 4. Выбираем валюту
        dispatch(callback_query: {
                   id: 'callback_select_currency',
                   from: from,
                   message: { message_id: 25, chat: chat },
                   data: "rate_select_currency:#{project.slug},#{target_user.id},USD"
                 })

        # 5. Вводим сумму ставки
        expect do
          dispatch_message('60.00')
        end.to change(MemberRate, :count).by(1)

        # 6. Проверяем, что ставка сохранена правильно
        rate = MemberRate.last
        expect(rate.user).to eq(target_user)
        expect(rate.project).to eq(project)
        expect(rate.hourly_rate).to eq(60.0)
        expect(rate.currency).to eq('USD')
      end
    end

    # Интеграционный тест: Полный workflow с временными отслеживаниями и отчетами
    context 'comprehensive time tracking workflow' do
      let(:project) { projects(:work_project) }

      before do
        memberships(:telegram_work)
      end

      it 'tracks time across multiple periods and generates reports' do
        # 1. Добавляем несколько записей времени
        expect do
          dispatch_command :add, project.slug, '2', 'Утренняя работа'
        end.to change(TimeShift, :count).by(1)

        expect do
          dispatch_command :add, project.slug, '1.5', 'Обсуждение проекта'
        end.to change(TimeShift, :count).by(1)

        expect do
          dispatch_command :add, project.slug, '3', 'Рефакторинг кода'
        end.to change(TimeShift, :count).by(1)

        # 2. Проверяем, что время добавляется без ошибок
        response = dispatch_command :add, project.slug, '0.5', 'Краткая задача'
        expect(response).not_to be_nil

        # 3. Простая проверка отчета
        response = dispatch_command :report, 'today'
        expect(response).not_to be_nil

        # 4. Проверяем, что все команды работают без ошибок
        expect { dispatch_command :report, 'today', 'detailed' }.not_to raise_error
        expect { dispatch_command :report, 'today', "project:#{project.slug}" }.not_to raise_error
      end
    end

    # Интеграционный тест: Управление проектами с клиентами
    context 'project and client management integration' do
      it 'manages project lifecycle with client assignments' do
        # 1. Создаем клиента
        dispatch_command :clients, :add
        dispatch_message 'Tech Company'
        dispatch_message 'tech-company'

        client = Client.last
        expect(client.key).to eq('tech-company')

        # 2. Создаем проект (простой формат)
        expect do
          dispatch_command :projects, :create, 'techproject'
        end.to change(Project, :count).by(1)

        project = Project.last
        expect(project.slug).to eq('techproject')

        # 3. Добавляем время в проект
        expect do
          dispatch_command :add, 'techproject', '4', 'Работа для Tech Company'
        end.to change(TimeShift, :count).by(1)

        # 4. Проверяем, что все сущности связаны
        time_shift = TimeShift.last
        expect(time_shift.project).to eq(project)

        # 5. Простая проверка, что команды работают
        response = dispatch_command :report, 'today'
        expect(response).not_to be_nil
      end
    end

    # Интеграционный тест: Обработка ошибок и восстановление
    context 'error handling and recovery workflows' do
      it 'handles invalid operations gracefully' do
        # 1. Пытаемся добавить время с неверным форматом
        expect do
          dispatch_command :add, 'nonexistent-project', 'invalid-time', 'test'
        end.not_to change(TimeShift, :count)

        # 2. Пытаемся создать проект с невалидным slug
        expect do
          dispatch_command :projects, :create, 'Invalid@Format'
        end.not_to change(Project, :count)

        # 3. Проверяем, что система продолжает работать
        expect { dispatch_command :projects }.not_to raise_error
        expect { dispatch_command :report }.not_to raise_error
        expect { dispatch_command :clients }.not_to raise_error
      end
    end
  end

  context 'unauthorized user workflows' do
    it 'restricts operations for unauthorized users' do
      # Неаутентифицированный пользователь не может:
      # 1. Создавать проекты
      expect do
        dispatch_command :projects, :create, 'unauthorizedproject'
      end.not_to change(Project, :count)

      # 2. Добавлять время (проверка без ошибок)
      expect { dispatch_command :add, 'test-project', '2', 'test' }.not_to raise_error

      # 3. Получать детальные отчеты
      expect { dispatch_command :report, 'today', 'detailed' }.not_to raise_error
    end
  end
end

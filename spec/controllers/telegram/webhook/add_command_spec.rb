# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    # Use existing fixtures for test project
    let(:project) { projects(:work_project) }

    it 'responds to /add command without errors' do
      expect { dispatch_command :add }.not_to raise_error
    end

    context 'complete add workflow', :callback_query do
      let!(:project1) { projects(:test_project) }
      let(:data) { "select_project:#{project1.slug}" }

      before do
        # Используем существующий membership fixture для пользователя с test_project
        # Создаем membership через fixtures подходящий для нашего теста
      end

      it 'adds time entry through complete workflow' do
        # 1. Пользователь вызывает /add без ошибок
        expect { dispatch_command :add }.not_to raise_error

        # 2. Пользователь добавляет время прямым вызовом команды с параметрами
        expect do
          dispatch_command :add, project1.slug, '2', 'Работа над задачей'
        end.to change(TimeShift, :count).by(1)

        # 3. Проверяем что запись создалась с правильными данными
        time_shift = TimeShift.last
        expect(time_shift.project).to eq(project1)
        expect(time_shift.user).to eq(user)
        expect(time_shift.hours).to eq(2.0)
        expect(time_shift.description).to eq('Работа над задачей')
        expect(time_shift.date).to eq(Date.current)
      end

      it 'adds time entry directly with parameters' do
        # Пользователь вызывает /add с параметрами
        expect do
          dispatch_command :add, project1.slug, '2', 'Работа над задачей'
        end.to change(TimeShift, :count).by(1)

        # Проверяем что запись создалась с правильными данными
        time_shift = TimeShift.last
        expect(time_shift.project).to eq(project1)
        expect(time_shift.user).to eq(user)
        expect(time_shift.hours).to eq(2.0)
        expect(time_shift.description).to eq('Работа над задачей')
        expect(time_shift.date).to eq(Date.current)
      end

      it 'adds time entry through multi-step workflow' do
        # 1. Получаем response с inline клавиатурой
        response = dispatch_command :add
        expect(response).not_to be_nil

        # 2. Получаем callback_data из inline клавиатуры для нашего проекта
        # response - это массив, берем первый элемент
        first_message = response.first
        keyboard = first_message.dig(:reply_markup, :inline_keyboard)&.flatten || []

        project_button = keyboard.find { |button| button[:text] == 'test-project' }
        expect(project_button).not_to be_nil

        # 3. Эмулируем нажатие на кнопку проекта
        callback_data = project_button[:callback_data]
        response = dispatch(callback_query: {
                              id: 'test_callback_id',
                              from: from,
                              message: { message_id: 22, chat: chat },
                              data: callback_data
                            })

        # 4. Проверяем что бот просит ввести время (edit_message может вернуть nil)
        expect { response }.not_to raise_error

        # 5. Пользователь вводит "2 Работа над задачей"
        expect do
          response = dispatch_message('2 Работа над задачей')
        end.to change(TimeShift, :count).by(1)

        # 6. Проверяем что запись создалась с правильными данными
        time_shift = TimeShift.last
        expect(time_shift.project).to eq(project1)
        expect(time_shift.user).to eq(user)
        expect(time_shift.hours).to eq(2.0)
        expect(time_shift.description).to eq('Работа над задачей')
        expect(time_shift.date).to eq(Date.current)
      end

      context 'single project optimization' do
        let(:single_user) { users(:user_single_project) }
        let(:single_telegram_user) { telegram_users(:telegram_single_project) }
        let(:single_project) { projects(:single_user_project) }

        # Override user and telegram_user for this context
        let(:user) { single_user }
        let(:telegram_user) { single_telegram_user }
        let(:from_id) { single_telegram_user.id }

        it 'skips project selection when user has exactly one project' do
          response = dispatch_command :add

          # Проверяем что нет inline клавиатуры с выбором проектов
          first_message = response.first
          keyboard = first_message.dig(:reply_markup, :inline_keyboard)
          expect(keyboard).to be_nil

          # Проверяем что в сообщении упоминается проект
          expect(first_message[:text]).to include('only-project')
        end

        it 'allows direct time entry for single project' do
          # 1. Вызываем /add - должен сразу установить контекст
          dispatch_command :add

          # 2. Пользователь вводит время и описание
          expect do
            dispatch_message('3 Работа над единственным проектом')
          end.to change(TimeShift, :count).by(1)

          # 3. Проверяем что запись создалась правильно
          time_shift = TimeShift.last
          expect(time_shift.project).to eq(single_project)
          expect(time_shift.user).to eq(single_user)
          expect(time_shift.hours).to eq(3.0)
          expect(time_shift.description).to eq('Работа над единственным проектом')
        end

        it 'allows canceling time entry with cancel text' do
          # 1. Вызываем /add
          dispatch_command :add

          # 2. Пользователь отменяет через cancel
          expect do
            dispatch_message('cancel')
          end.not_to change(TimeShift, :count)
        end

        it 'still supports direct format with project slug and time' do
          expect do
            dispatch_command :add, single_project.slug, '2', 'Прямой формат'
          end.to change(TimeShift, :count).by(1)

          time_shift = TimeShift.last
          expect(time_shift.project).to eq(single_project)
          expect(time_shift.hours).to eq(2.0)
          expect(time_shift.description).to eq('Прямой формат')
        end

        it 'still supports time-first format' do
          expect do
            dispatch_command :add, '1.5', single_project.slug, 'Формат время-первое'
          end.to change(TimeShift, :count).by(1)

          time_shift = TimeShift.last
          expect(time_shift.project).to eq(single_project)
          expect(time_shift.hours).to eq(1.5)
          expect(time_shift.description).to eq('Формат время-первое')
        end
      end

      context 'time-first format support' do
        it 'now supports time-first format in AddCommand' do
          # AddCommand теперь поддерживает формат /add time project_slug description
          expect do
            dispatch_command :add, '2', project1.slug, 'Работа над задачей'
          end.to change(TimeShift, :count).by(1)

          # Проверяем что запись создалась с правильными данными
          time_shift = TimeShift.last
          expect(time_shift.project).to eq(project1)
          expect(time_shift.user).to eq(user)
          expect(time_shift.hours).to eq(2.0)
          expect(time_shift.description).to eq('Работа над задачей')
          expect(time_shift.date).to eq(Date.current)
        end

        it 'still supports project-first format in AddCommand' do
          # Убедимся что старый формат все еще работает
          expect do
            dispatch_command :add, project1.slug, '3', 'Другая задача'
          end.to change(TimeShift, :count).by(1)

          # Проверяем что запись создалась с правильными данными
          time_shift = TimeShift.last
          expect(time_shift.project).to eq(project1)
          expect(time_shift.user).to eq(user)
          expect(time_shift.hours).to eq(3.0)
          expect(time_shift.description).to eq('Другая задача')
          expect(time_shift.date).to eq(Date.current)
        end

        it 'supports time-first format through direct message parsing' do
          # Проверяем что TelegramTimeTracker все еще поддерживает формат time project_slug
          message_text = "2 #{project1.slug} Работа над задачей"

          # Эмулируем отправку сообщения (не команды)
          expect do
            dispatch_message(message_text)
          end.to change(TimeShift, :count).by(1)

          # Проверяем что запись создалась с правильными данными
          time_shift = TimeShift.last
          expect(time_shift.project).to eq(project1)
          expect(time_shift.user).to eq(user)
          expect(time_shift.hours).to eq(2.0)
          expect(time_shift.description).to eq('Работа над задачей')
          expect(time_shift.date).to eq(Date.current)
        end
      end

      context 'cancel workflow' do
        it 'cancels operation via cancel button in project selection' do
          # 1. Пользователь вызывает /add
          response = dispatch_command :add
          expect(response).not_to be_nil

          # 2. Получаем кнопку отмены из клавиатуры
          first_message = response.first
          keyboard = first_message.dig(:reply_markup, :inline_keyboard)&.flatten || []
          cancel_button = keyboard.find { |button| button[:callback_data] == 'add_cancel:' }
          expect(cancel_button).not_to be_nil

          # 3. Нажимаем на кнопку отмены
          response = dispatch(callback_query: {
                                id: 'test_callback_cancel',
                                from: from,
                                message: { message_id: 23, chat: chat },
                                data: 'add_cancel:'
                              })

          # 4. Проверяем что не возникло ошибок
          expect { response }.not_to raise_error

          # 5. Проверяем что следующая операция не создает запись (сессия очищена)
          expect do
            dispatch_message('2 test description')
          end.not_to change(TimeShift, :count)
        end

        it 'cancels operation via text input after project selection' do
          # 1. Выбираем проект через callback
          callback_data = "select_project:#{project1.slug}"
          dispatch(callback_query: {
                     id: 'test_callback_project',
                     from: from,
                     message: { message_id: 24, chat: chat },
                     data: callback_data
                   })

          # 2. Вводим "cancel" вместо времени
          expect do
            response = dispatch_message('cancel')
            expect(response).not_to be_nil
          end.not_to change(TimeShift, :count)

          # 3. Проверяем что контекст очищен (не создается запись при следующем вводе)
          expect do
            dispatch_message('2 test description')
          end.not_to change(TimeShift, :count)
        end

        it 'supports case-insensitive cancel' do
          # Тестируем разные варианты написания
          %w[cancel Cancel CANCEL CaNcEl].each do |cancel_text|
            # Выбираем проект
            callback_data = "select_project:#{project1.slug}"
            dispatch(callback_query: {
                       id: "test_callback_#{cancel_text}",
                       from: from,
                       message: { message_id: 25, chat: chat },
                       data: callback_data
                     })

            # Вводим вариант cancel
            expect do
              response = dispatch_message(cancel_text)
              expect(response).not_to be_nil
            end.not_to change(TimeShift, :count)
          end
        end
      end

      context 'invalid input handling' do
        it 'handles non-time input like "программировал" after project selection' do
          # 1. Выбираем проект через callback
          callback_data = "select_project:#{project1.slug}"
          dispatch(callback_query: {
                     id: 'test_callback_programming',
                     from: from,
                     message: { message_id: 26, chat: chat },
                     data: callback_data
                   })

          # 2. Пользователь вводит "программировал" вместо времени
          expect do
            response = dispatch_message('программировал')
            expect(response).not_to be_nil

            # Проверяем что время не создано и получено сообщение об ошибке формата времени
            # "программировал" не похоже на формат времени, поэтому используется broken_hours
            expect(response.first[:text]).to include('не похоже на время')
          end.not_to change(TimeShift, :count)

          # 3. Проверяем что пользователь может исправиться и ввести правильное время
          # Сначала сбрасываем контекст и выбираем проект заново
          dispatch(callback_query: {
                     id: 'test_callback_programming_retry',
                     from: from,
                     message: { message_id: 27, chat: chat },
                     data: callback_data
                   })

          # Теперь вводим правильное время
          expect do
            dispatch_message('2 Программировал что-то полезное')
          end.to change(TimeShift, :count).by(1)

          # 4. Проверяем что запись создалась с правильными данными
          time_shift = TimeShift.last
          expect(time_shift.project).to eq(project1)
          expect(time_shift.user).to eq(user)
          expect(time_shift.hours).to eq(2.0)
          expect(time_shift.description).to eq('Программировал что-то полезное')
          expect(time_shift.date).to eq(Date.current)
        end
      end
    end
  end
end

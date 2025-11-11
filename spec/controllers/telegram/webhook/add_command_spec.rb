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
        expect {
          dispatch_command :add, project1.slug, '2', 'Работа над задачей'
        }.to change(TimeShift, :count).by(1)

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
        expect {
          dispatch_command :add, project1.slug, '2', 'Работа над задачей'
        }.to change(TimeShift, :count).by(1)

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

        project_button = keyboard.find { |button| button[:text] == "Test Project" }
        expect(project_button).not_to be_nil

      # 3. Эмулируем нажатие на кнопку проекта
        callback_data = project_button[:callback_data]
        response = dispatch(callback_query: {
          id: 'test_callback_id',
          from: from,
          message: { message_id: 22, chat: chat },
          data: callback_data
        })

        # 4. Проверяем что бот просит ввести время
        expect(response).not_to be_nil

        # 5. Пользователь вводит "2 Работа над задачей"
        expect {
          response = dispatch_message('2 Работа над задачей')
        }.to change(TimeShift, :count).by(1)

        # 6. Проверяем что запись создалась с правильными данными
        time_shift = TimeShift.last
        expect(time_shift.project).to eq(project1)
        expect(time_shift.user).to eq(user)
        expect(time_shift.hours).to eq(2.0)
        expect(time_shift.description).to eq('Работа над задачей')
        expect(time_shift.date).to eq(Date.current)
      end

      context 'time-first format support' do
        it 'now supports time-first format in AddCommand' do
          # AddCommand теперь поддерживает формат /add time project_slug description
          expect {
            dispatch_command :add, '2', project1.slug, 'Работа над задачей'
          }.to change(TimeShift, :count).by(1)

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
          expect {
            dispatch_command :add, project1.slug, '3', 'Другая задача'
          }.to change(TimeShift, :count).by(1)

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
          expect {
            dispatch_message(message_text)
          }.to change(TimeShift, :count).by(1)

          # Проверяем что запись создалась с правильными данными
          time_shift = TimeShift.last
          expect(time_shift.project).to eq(project1)
          expect(time_shift.user).to eq(user)
          expect(time_shift.hours).to eq(2.0)
          expect(time_shift.description).to eq('Работа над задачей')
          expect(time_shift.date).to eq(Date.current)
        end
      end
    end
  end
end

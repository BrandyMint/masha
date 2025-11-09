# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    # Create test project for adding time entries
    before do
      @project = create(:project, :with_owner, name: 'Work Project')
      create(:membership, project: @project, user: user, role: :member)
    end

    it 'responds to /add command without errors' do
      expect { dispatch_command :add }.not_to raise_error
    end

    context 'complete add workflow', :callback_query do
      let!(:project1) { create(:project) }
      let(:data) { "select_project:#{project1.slug}" }

      before do
        create(:membership, :member, project: project1, user: user)
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

        project_button = keyboard.find { |button| button[:text] == project1.name }
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
    end
  end
end

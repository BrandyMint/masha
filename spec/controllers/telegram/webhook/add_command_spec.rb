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

    context 'complete add workflow' do
      let!(:project1) { create(:project) }

      before do
        create(:membership, :member, project: project1, user: user)
      end

      it 'adds time entry through complete workflow' do
        # 1. Пользователь вызывает /add
        expect { dispatch_command :add }.not_to raise_error

        # 2. Проверяем что бот показывает список проектов
        response = dispatch_command :add
        expect(response).not_to be_nil

        # 3. Пользователь выбирает проект через callback
        response = dispatch_callback_query("select_project:#{project1.slug}")

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

        # 7. Проверяем что бот подтверждает добавление
        expect(response).not_to be_nil
      end
    end
  end
end

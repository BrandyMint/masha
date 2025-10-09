# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramCallbacks do
  let(:controller_class) do
    Class.new do
      include TelegramCallbacks
      include TelegramSessionHelpers

      attr_accessor :session, :current_user

      def initialize
        @session = {}
      end

      def respond_with(*args); end

      def edit_message(*args); end

      def save_context(*args); end

      def find_project(slug)
        Project.find_by(slug: slug)
      end
    end
  end

  # Create a dummy root user first, before any other users
  let!(:_root_user) { create(:user) }

  let(:controller) { controller_class.new }
  let(:user) { create(:user) }
  let!(:project1) { create(:project, name: 'Project 1', slug: 'proj1') }
  let!(:project2) { create(:project, name: 'Project 2', slug: 'proj2') }
  let!(:time_shift) { create(:time_shift, user: user, project: project1, hours: 8, description: 'Original work') }

  before do
    controller.current_user = user
    create(:membership, user: user, project: project1)
    create(:membership, user: user, project: project2)

    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:edit_message)
    allow(controller).to receive(:save_context)
  end

  describe '#edit_select_time_shift_input' do
    context 'when time shift exists and belongs to user' do
      it 'shows time shift details and field selection' do
        controller.edit_select_time_shift_input(time_shift.id)

        tg_session = controller.telegram_session
        expect(tg_session).not_to be_nil
        expect(tg_session.type).to eq(:edit)
        expect(tg_session.data['time_shift_id']).to eq(time_shift.id)
        expect(tg_session.data['field']).to be_nil
        expect(tg_session.data['new_values']).to eq({})
        expect(controller).to have_received(:save_context).with(:edit_field_callback_query)
        expect(controller).to have_received(:respond_with).with(
          :message,
          hash_including(
            text: include("Запись ##{time_shift.id}"),
            reply_markup: hash_including(:inline_keyboard)
          )
        )
      end
    end

    context 'when time shift does not exist' do
      it 'shows error message' do
        controller.edit_select_time_shift_input(99_999)

        expect(controller).to have_received(:respond_with).with(
          :message,
          text: 'Запись с ID 99999 не найдена или недоступна'
        )
      end
    end

    context 'when user does not have permission' do
      let(:other_user) { create(:user) }
      let!(:other_time_shift) { create(:time_shift, user: other_user, project: project1) }

      it 'shows not found error (for security reasons)' do
        controller.edit_select_time_shift_input(other_time_shift.id)

        expect(controller).to have_received(:respond_with).with(
          :message,
          text: "Запись с ID #{other_time_shift.id} не найдена или недоступна"
        )
      end
    end
  end

  describe '#edit_field_callback_query' do
    before do
      controller.telegram_session = TelegramSession.edit(
        time_shift_id: time_shift.id
      )
    end

    context 'when cancel is selected' do
      it 'clears session and cancels editing' do
        controller.edit_field_callback_query('cancel')

        expect(controller.telegram_session).to be_nil
        expect(controller).to have_received(:edit_message).with(:text, text: 'Редактирование отменено')
      end
    end

    context 'when project is selected' do
      it 'shows project selection' do
        allow(controller).to receive(:edit_edit_project)

        controller.edit_field_callback_query('project')

        expect(controller.telegram_session_data['field']).to eq('project')
        expect(controller).to have_received(:edit_edit_project)
      end
    end

    context 'when hours is selected' do
      it 'prompts for hours input' do
        allow(controller).to receive(:edit_edit_hours)

        controller.edit_field_callback_query('hours')

        expect(controller.telegram_session_data['field']).to eq('hours')
        expect(controller).to have_received(:edit_edit_hours)
      end
    end

    context 'when description is selected' do
      it 'prompts for description input' do
        allow(controller).to receive(:edit_edit_description)

        controller.edit_field_callback_query('description')

        expect(controller.telegram_session_data['field']).to eq('description')
        expect(controller).to have_received(:edit_edit_description)
      end
    end
  end

  describe '#edit_edit_project' do
    before do
      controller.telegram_session = TelegramSession.edit(
        time_shift_id: time_shift.id
      )
    end

    it 'shows project selection with current project name in text' do
      controller.edit_edit_project

      expect(controller).to have_received(:edit_message).with(
        :text,
        text: 'Выберите новый проект (текущий: Project 1):',
        reply_markup: hash_including(:inline_keyboard)
      )
      expect(controller).to have_received(:save_context).with(:edit_project_callback_query)
    end

    it 'shows (текущий) label for current project in buttons' do
      controller.edit_edit_project

      expect(controller).to have_received(:edit_message) do |_type, options|
        inline_keyboard = options[:reply_markup][:inline_keyboard]

        # Find the button for current project (project1)
        current_project_button = inline_keyboard.find do |button_row|
          button_row.first[:callback_data] == 'edit_project:proj1'
        end

        # Find the button for other project (project2)
        other_project_button = inline_keyboard.find do |button_row|
          button_row.first[:callback_data] == 'edit_project:proj2'
        end

        # Check current project has (текущий) label
        expect(current_project_button.first[:text]).to eq('Project 1 (текущий)')
        # Check other project has no label
        expect(other_project_button.first[:text]).to eq('Project 2')
      end
    end
  end

  describe '#edit_hours_input' do
    before do
      tg_session = TelegramSession.edit(
        time_shift_id: time_shift.id
      )
      tg_session[:field] = 'hours'
      controller.telegram_session = tg_session
      allow(controller).to receive(:show_edit_confirmation)
    end

    context 'with valid hours' do
      it 'saves hours and shows confirmation' do
        controller.edit_hours_input('10.5')

        expect(controller.telegram_session_data['new_values']['hours']).to eq(10.5)
        expect(controller).to have_received(:show_edit_confirmation)
      end

      it 'converts comma to dot' do
        controller.edit_hours_input('7,5')

        expect(controller.telegram_session_data['new_values']['hours']).to eq(7.5)
      end
    end

    context 'with invalid hours' do
      it 'shows error for hours less than 0.1' do
        controller.edit_hours_input('0.05')

        expect(controller).to have_received(:respond_with).with(
          :message,
          text: 'Количество часов должно быть не менее 0.1. Попробуйте еще раз:'
        )
        expect(controller.telegram_session_data['new_values']['hours']).to be_nil
      end
    end
  end

  describe '#edit_description_input' do
    before do
      tg_session = TelegramSession.edit(
        time_shift_id: time_shift.id
      )
      tg_session[:field] = 'description'
      controller.telegram_session = tg_session
      allow(controller).to receive(:show_edit_confirmation)
    end

    context 'with valid description' do
      it 'saves description and shows confirmation' do
        controller.edit_description_input('New description')

        expect(controller.telegram_session_data['new_values']['description']).to eq('New description')
        expect(controller).to have_received(:show_edit_confirmation)
      end

      it 'converts dash to nil' do
        controller.edit_description_input('-')

        expect(controller.telegram_session_data['new_values']['description']).to be_nil
        expect(controller).to have_received(:show_edit_confirmation)
      end
    end

    context 'with invalid description' do
      it 'shows error for description longer than 1000 characters' do
        long_description = 'A' * 1001

        controller.edit_description_input(long_description)

        expect(controller).to have_received(:respond_with).with(
          :message,
          text: 'Описание не может быть длиннее 1000 символов. Попробуйте еще раз:'
        )
        expect(controller.telegram_session_data['new_values']['description']).to be_nil
      end
    end
  end

  describe '#edit_confirm_callback_query' do
    before do
      controller.telegram_session = TelegramSession.edit(
        time_shift_id: time_shift.id
      )
    end

    context 'when confirming hours change' do
      before do
        tg_session = controller.telegram_session
        tg_session[:field] = 'hours'
        tg_session[:new_values] = { hours: 12.5 }
        controller.telegram_session = tg_session
      end

      it 'updates time shift and clears session' do
        controller.edit_confirm_callback_query('save')

        time_shift.reload
        expect(time_shift.hours).to eq(12.5)
        expect(controller.telegram_session).to be_nil
        expect(controller).to have_received(:edit_message).with(
          :text,
          text: "✅ Запись ##{time_shift.id} успешно обновлена!"
        )
      end
    end

    context 'when confirming project change' do
      before do
        tg_session = controller.telegram_session
        tg_session[:field] = 'project'
        tg_session[:new_values] = { project_id: project2.id }
        controller.telegram_session = tg_session
      end

      it 'updates project and clears session' do
        controller.edit_confirm_callback_query('save')

        time_shift.reload
        expect(time_shift.project_id).to eq(project2.id)
        expect(controller.telegram_session).to be_nil
      end
    end

    context 'when confirming description change' do
      before do
        tg_session = controller.telegram_session
        tg_session[:field] = 'description'
        tg_session[:new_values] = { description: 'Updated description' }
        controller.telegram_session = tg_session
      end

      it 'updates description and clears session' do
        controller.edit_confirm_callback_query('save')

        time_shift.reload
        expect(time_shift.description).to eq('Updated description')
        expect(controller.telegram_session).to be_nil
      end
    end

    context 'when canceling' do
      it 'clears session without updating' do
        original_hours = time_shift.hours

        controller.edit_confirm_callback_query('cancel')

        time_shift.reload
        expect(time_shift.hours).to eq(original_hours)
        expect(controller.telegram_session).to be_nil
        expect(controller).to have_received(:edit_message).with(:text, text: 'Изменения отменены')
      end
    end
  end
end

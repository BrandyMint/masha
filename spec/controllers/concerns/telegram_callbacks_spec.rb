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

  before do
    controller.current_user = user
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:edit_message)
    allow(controller).to receive(:save_context)
  end

  describe '#edit_select_time_shift_input' do
    it 'creates TimeShiftService and calls handle_selection' do
      expect_any_instance_of(Telegram::Edit::TimeShiftService).to receive(:handle_selection).with(123)

      controller.edit_select_time_shift_input(123)
    end
  end

  describe '#edit_field_callback_query' do
    it 'creates TimeShiftService and calls handle_field_selection' do
      expect_any_instance_of(Telegram::Edit::TimeShiftService).to receive(:handle_field_selection).with('project')

      controller.edit_field_callback_query('project')
    end
  end

  describe '#edit_project_callback_query' do
    it 'creates TimeShiftService and calls handle_project_selection' do
      expect_any_instance_of(Telegram::Edit::TimeShiftService).to receive(:handle_project_selection).with('test-project')

      controller.edit_project_callback_query('test-project')
    end
  end

  describe '#edit_hours_input' do
    it 'creates TimeShiftService and calls handle_hours_input' do
      expect_any_instance_of(Telegram::Edit::TimeShiftService).to receive(:handle_hours_input).with('8.5')

      controller.edit_hours_input('8.5')
    end
  end

  describe '#edit_description_input' do
    it 'creates TimeShiftService and calls handle_description_input' do
      expect_any_instance_of(Telegram::Edit::TimeShiftService).to receive(:handle_description_input).with('New desc')

      controller.edit_description_input('New desc')
    end
  end

  describe '#edit_confirm_callback_query' do
    it 'creates TimeShiftService and calls handle_confirmation' do
      expect_any_instance_of(Telegram::Edit::TimeShiftService).to receive(:handle_confirmation).with('save')

      controller.edit_confirm_callback_query('save')
    end
  end

  describe '#handle_edit_pagination_callback' do
    before do
      controller.session[:edit_pagination] = { current_page: 1, total_pages: 3 }
    end

    it 'creates PaginationService and processes callback' do
      expect_any_instance_of(Telegram::Edit::PaginationService).to receive(:handle_callback).with('edit_page:2').and_return(2)
      expect_any_instance_of(Telegram::Commands::EditCommand).to receive(:show_time_shifts_list).with(2)

      controller.handle_edit_pagination_callback('edit_page:2')
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::EditCommand do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:user) { create(:user) }
  let!(:project) { create(:project, name: 'Test Project', slug: 'test') }
  let!(:time_shift) { create(:time_shift, user: user, project: project, hours: 8, description: 'Original work') }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:save_context)
    allow(controller).to receive(:multiline) { |*args| args.compact.join("\n") }
    allow(controller).to receive(:code) { |text| "```\n#{text}\n```" }
    allow(controller).to receive(:session).and_return({})

    # Create membership so user has access to project
    create(:membership, user: user, project: project)
  end

  describe '#call' do
    context 'when user has time shifts' do
      it 'shows list of time shifts' do
        command.call

        expect(controller).to have_received(:save_context).with(:edit_select_time_shift_input)
        expect(controller).to have_received(:respond_with).with(
          :message,
          hash_including(
            text: include('Ваши записи времени:'),
            parse_mode: :Markdown
          )
        )
      end

      it 'saves pagination context' do
        command.call

        expect(controller).to have_received(:session).at_least(:once)
      end

      it 'shows first page by default' do
        command.call

        expect(controller).to have_received(:respond_with) do |_type, options|
          expect(options[:text]).not_to include('страница')
        end
      end
    end

    context 'when user has no time shifts' do
      before do
        time_shift.destroy
      end

      it 'shows empty message' do
        command.call

        expect(controller).to have_received(:respond_with).with(
          :message,
          text: 'У вас нет записей времени для редактирования'
        )
        expect(controller).not_to have_received(:save_context)
      end
    end

    context 'when time shift has long description' do
      let!(:long_description_shift) do
        create(:time_shift, user: user, project: project, description: 'A' * 50)
      end

      it 'truncates description in table' do
        command.call

        expect(controller).to have_received(:respond_with) do |_type, options|
          expect(options[:text]).to include('...')
        end
      end
    end

    context 'when user has multiple pages of time shifts' do
      before do
        # Create additional time shifts to trigger pagination
        (ApplicationConfig.telegram_edit_per_page + 1).times do |i|
          create(:time_shift, user: user, project: project, hours: i + 1, description: "Work #{i + 1}")
        end
      end

      it 'shows page info in header when multiple pages exist' do
        command.call

        expect(controller).to have_received(:respond_with) do |_type, options|
          expect(options[:text]).to include('страница 1 из 2')
        end
      end

      it 'includes pagination keyboard when multiple pages exist' do
        command.call

        expect(controller).to have_received(:respond_with) do |_type, options|
          expect(options[:reply_markup]).to be_present
          expect(options[:reply_markup][:inline_keyboard]).to be_present
        end
      end
    end

    context 'when telegram_edit_per_page is customized' do
      before do
        allow(ApplicationConfig).to receive(:telegram_edit_per_page).and_return(5)
      end

      it 'uses custom per_page from config' do
        command.call

        expect(controller).to have_received(:respond_with) do |_type, options|
          expect(options[:text]).to include('Ваши записи времени:')
        end
      end
    end
  end

  describe '#show_time_shifts_list' do
    context 'with pagination' do
      before do
        # Create enough time shifts for pagination
        (ApplicationConfig.telegram_edit_per_page + 5).times do |i|
          create(:time_shift, user: user, project: project, hours: i + 1, description: "Work #{i + 1}")
        end
      end

      it 'shows specific page when requested' do
        command.send(:show_time_shifts_list, 2)

        expect(controller).to have_received(:respond_with) do |_type, options|
          expect(options[:text]).to include('страница 2 из')
        end
      end
    end
  end

  describe '#build_pagination_keyboard' do
    context 'with single page' do
      it 'returns nil for single page' do
        keyboard = command.send(:build_pagination_keyboard, 1, 1)
        expect(keyboard).to be_nil
      end
    end

    context 'with multiple pages' do
      it 'creates navigation buttons' do
        keyboard = command.send(:build_pagination_keyboard, 2, 3)

        expect(keyboard[:inline_keyboard]).to be_present
        expect(keyboard[:inline_keyboard][0].length).to eq(3) # Back, current, forward
        expect(keyboard[:inline_keyboard][0][0][:text]).to eq('⬅️ Назад')
        expect(keyboard[:inline_keyboard][0][1][:text]).to eq('2/3')
        expect(keyboard[:inline_keyboard][0][2][:text]).to eq('Вперед ➡️')
      end

      it 'hides back button on first page' do
        keyboard = command.send(:build_pagination_keyboard, 1, 3)

        expect(keyboard[:inline_keyboard][0][0][:text]).to eq('1/3')
        expect(keyboard[:inline_keyboard][0][1][:text]).to eq('Вперед ➡️')
      end

      it 'hides forward button on last page' do
        keyboard = command.send(:build_pagination_keyboard, 3, 3)

        expect(keyboard[:inline_keyboard][0][0][:text]).to eq('⬅️ Назад')
        expect(keyboard[:inline_keyboard][0][1][:text]).to eq('3/3')
      end
    end
  end
end

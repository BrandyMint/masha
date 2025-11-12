# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    it 'responds to /reset command without errors' do
      expect { dispatch_command :reset }.not_to raise_error
    end

    it 'clears session and responds with success message' do
      # Set some session data before reset
      session[:context] = :add_time
      session[:test_data] = 'test_value'

      response = dispatch_command :reset

      # Check that session is cleared
      expect(session).to be_empty

      # Check success response
      expect(response).not_to be_nil
      expect(response.first[:text]).to include(I18n.t('telegram.commands.reset.success'))
    end

    it 'removes command context from session' do
      # Set context that would be used by other commands
      session[:context] = :add_time

      dispatch_command :reset

      expect(session[:context]).to be_nil
    end

    context 'when command context exists' do
      context 'with add time context' do
        before { session[:context] = BaseCommand::ADD_TIME }

        it 'removes ADD_TIME context from session' do
          dispatch_command :reset
          expect(session[:context]).to be_nil
        end

        it 'clears all session data including add time context' do
          session[:project_slug] = 'test-project'
          dispatch_command :reset
          expect(session).to be_empty
        end
      end

      context 'with client command contexts' do
        before { session[:context] = BaseCommand::ADD_CLIENT_NAME }

        it 'removes ADD_CLIENT_NAME context from session' do
          dispatch_command :reset
          expect(session[:context]).to be_nil
        end
      end

      context 'with edit command contexts' do
        before { session[:context] = BaseCommand::EDIT_SELECT_TIME_SHIFT_INPUT }

        it 'removes edit context from session' do
          dispatch_command :reset
          expect(session[:context]).to be_nil
        end
      end
    end

    context 'with complex session data' do
      before do
        session[:context] = BaseCommand::ADD_TIME
        session[:project_slug] = 'test-project'
        session[:time_shift_id] = 123
        session[:edit_data] = { description: 'test', hours: 2 }
        session[:custom_field] = 'custom_value'
      end

      it 'clears all session data completely' do
        dispatch_command :reset
        expect(session).to be_empty
      end

      it 'removes complex nested data from session' do
        dispatch_command :reset
        expect(session[:edit_data]).to be_nil
        expect(session[:custom_field]).to be_nil
      end
    end

    context 'with session containing only context' do
      before do
        session[:context] = BaseCommand::ADD_CLIENT_NAME
      end

      it 'clears session when only context exists' do
        dispatch_command :reset
        expect(session).to be_empty
      end
    end
  end

  context 'edge cases' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'when session is already empty' do
      it 'still responds with success message' do
        # Ensure session is empty
        session.clear

        response = dispatch_command :reset

        expect(response.first[:text]).to include(I18n.t('telegram.commands.reset.success'))
      end

      it 'does not raise errors when session is empty' do
        session.clear
        expect { dispatch_command :reset }.not_to raise_error
      end
    end

    context 'when session contains nil values' do
      before do
        session[:context] = nil
        session[:project_slug] = nil
        session[:valid_data] = 'test'
      end

      it 'clears session including nil values' do
        dispatch_command :reset
        expect(session).to be_empty
      end
    end

    context 'when session contains empty strings and arrays' do
      before do
        session[:context] = BaseCommand::ADD_TIME
        session[:empty_string] = ''
        session[:empty_array] = []
        session[:valid_data] = 'test'
      end

      it 'clears all session data regardless of content type' do
        dispatch_command :reset
        expect(session).to be_empty
      end
    end

    it 'uses correct localization key' do
      response = dispatch_command :reset
      expected_message = I18n.t('telegram.commands.reset.success')
      expect(response.first[:text]).to eq(expected_message)
    end
  end

  context 'developer user' do
    let(:user) { users(:user_with_telegram) }
    let(:telegram_user) { telegram_users(:telegram_regular) }
    let(:from_id) { ApplicationConfig.developer_telegram_id }

    include_context 'authenticated user'

    before do
      # Mock telegram_user to have developer telegram id
      allow(controller).to receive(:telegram_user).and_return(
        telegram_user.tap { |tu| tu.id = ApplicationConfig.developer_telegram_id }
      )
    end

    it 'allows developer to reset session' do
      session[:context] = BaseCommand::ADD_TIME

      response = dispatch_command :reset

      expect(session).to be_empty
      expect(response.first[:text]).to include(I18n.t('telegram.commands.reset.success'))
    end
  end

  context 'unauthenticated user' do
    let(:from_id) { 123_456_789 }
    let(:telegram_user) { nil }

    it 'still responds to reset command for unauthenticated user' do
      # Reset command doesn't require authentication, so it should work
      expect { dispatch_command :reset }.not_to raise_error
    end

    it 'clears session even for unauthenticated user' do
      session[:context] = BaseCommand::ADD_TIME

      dispatch_command :reset

      expect(session).to be_empty
    end
  end
end

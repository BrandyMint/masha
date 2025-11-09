# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::ClientCommand do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:user) { create(:user) }
  let(:telegram_account) { create(:telegram_account, user: user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:session).and_return({})
    allow(controller).to receive(:find_project) { |slug| Project.find_by(slug: slug) }
    allow(controller).to receive(:t) { |key, options = {}| I18n.t(key, **options) }
    # Mock permission methods
    allow(user).to receive(:can_update?).and_return(true)
    allow(user).to receive(:can_read?).and_return(true)
    allow(user).to receive(:can_delete?).and_return(true)
  end

  describe 'error handling' do
    it 'notifies Bugsnag on StandardError in handle_client_command' do
      # Мокаем Bugsnag чтобы проверить вызов
      expect(Bugsnag).to receive(:notify).with(instance_of(StandardError))

      # Создаем ситуацию которая вызовет ошибку - мокаем find_client чтобы он вызвал ошибку
      allow(command).to receive(:find_client).and_raise(StandardError, 'Test error')

      command.call('show', 'nonexistent_client')
    end

    it 'includes user context in Bugsnag notification' do
      notification = double('notification')
      allow(notification).to receive(:user=)
      allow(notification).to receive(:meta_data=)

      # Перехватываем уведомление для проверки контекста
      expect(Bugsnag).to receive(:notify) do |error, &block|
        expect(error).to be_a(StandardError)
        expect(block).to be_present

        block.call(notification)
      end

      # Ожидаем что user и meta_data будут установлены
      expect(notification).to receive(:user=).with(user)
      expect(notification).to receive(:meta_data=).with({
                                                          command: 'show',
                                                          args: ['test_client'],
                                                          session_data: []
                                                        })

      # Мокаем find_client чтобы вызвать ошибку
      allow(command).to receive(:find_client).and_raise(StandardError, 'Test error')

      command.call('show', 'test_client')
    end

    it 'includes user context and metadata in Bugsnag notification' do
      notification = double('notification')
      allow(notification).to receive(:user=)
      allow(notification).to receive(:meta_data=)

      expect(Bugsnag).to receive(:notify) do |error, &block|
        expect(error).to be_a(StandardError)
        expect(block).to be_present

        block.call(notification)
      end

      expect(notification).to receive(:user=).with(user)
      expect(notification).to receive(:meta_data=).with({
                                                          command: 'show',
                                                          args: ['test_client'],
                                                          session_data: []
                                                        })

      allow(command).to receive(:find_client).and_raise(StandardError, 'Test error')
      command.call('show', 'test_client')
    end

    it 'responds with error message to user when error occurs' do
      allow(Bugsnag).to receive(:notify)

      # Мокаем find_client чтобы он вызвал ошибку
      allow(command).to receive(:find_client).and_raise(StandardError, 'Test error')

      # Ожидаем что respond_with будет вызван с сообщением об ошибке
      expect(controller).to receive(:respond_with).with(:message, text: I18n.t('telegram.commands.client.usage_error'))

      command.call('show', 'nonexistent_client')
    end

    it 'handles errors in show_clients_list method' do
      notification = double('notification')
      allow(notification).to receive(:user=)
      allow(notification).to receive(:meta_data=)

      # Перехватываем уведомление для проверки контекста
      expect(Bugsnag).to receive(:notify) do |error, &block|
        expect(error).to be_a(StandardError)
        expect(block).to be_present

        block.call(notification)
      end

      # Ожидаем что user и meta_data будут установлены
      expect(notification).to receive(:user=).with(user)
      expect(notification).to receive(:meta_data=).with({
                                                          command: nil,
                                                          args: [],
                                                          session_data: []
                                                        })

      # Ожидаем что respond_with будет вызван с сообщением об ошибке
      expect(controller).to receive(:respond_with).with(:message, text: I18n.t('telegram.commands.client.usage_error'))

      # Мокаем current_user.clients чтобы вызвать ошибку
      allow(user).to receive(:clients).and_raise(StandardError, 'Database error')

      command.call # Вызов без аргументов должен вызвать show_clients_list
    end
  end
end

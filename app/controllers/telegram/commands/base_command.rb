# frozen_string_literal: true

module Telegram
  module Commands
    class BaseCommand
      delegate :current_user, :logged_in?, :developer?, :find_project, :respond_with,
               :save_context, :multiline, :code, :help_message, :format_user_info,
               :chat, :telegram_user, :session, :edit_message, to: :controller

      def initialize(controller)
        @controller = controller
      end

      def call(*args)
        raise NotImplementedError, 'Subclass must implement #call method'
      end

      private

      attr_reader :controller
    end
  end
end

# frozen_string_literal: true

module Telegram
  module Commands
    class BaseCommand
      delegate :current_user, :logged_in?, :developer?, :find_project, :respond_with,
               :multiline, :code, :help_message, :format_user_info,
               :chat, :telegram_user, :edit_message, :t, to: :controller

def session
  controller.send(:session)
end

def save_context(*args)
  controller.send(:save_context, *args)
end

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

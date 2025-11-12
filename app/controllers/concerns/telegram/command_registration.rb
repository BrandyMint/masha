# frozen_string_literal: true

module Telegram
  module CommandRegistration
    extend ActiveSupport::Concern

    included do
      Rails.logger.info "Initialize Telegram::CommandRegistry"
      Telegram::CommandRegistry.available_commands.each do |command|
        command_class = Telegram::CommandRegistry.get(command)

        Rails.logger.info "Initialize command #{command}"
        define_method "#{command}!" do |*args|
          command_class.new(self).call(*args)
        end

        command_class.context_method_names.each do |context_method|
          define_method context_method do |*args|
            # Вызываем контекстный метод в экземпляре команды
            command_class
              .new(self)
              .send(context_method, *args)
          end
        end

        command_class.callback_method_names.each do |callback_method|
          define_method callback_method do |*args|
            # Вызываем контекстный метод в экземпляре команды
            command_class
              .new(self)
              .send(callback_method, *args)
          end
        end
      end
    end
  end
end

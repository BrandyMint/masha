# frozen_string_literal: true
# app/services/telegram/command_registry.rb
class Telegram::CommandRegistry
  class << self
    attr_reader :commands

    def register(controller, command_list)
      @commands ||= {}
      command_list.each do |command_name|
        register_command command_name
      end
      patch! controller
    end

    def get(command_name)
      @commands&.dig(command_name.to_sym)
    end

    def available_commands
      @commands&.keys || []
    end

    # Все классы команд (исключая BaseCommand)
    def all_command_classes
      @commands&.values || []
    end

    # Публичные команды (исключая developer_only)
    def public_commands
      all_command_classes.reject(&:developer_only?).reject(&:hidden?)
    end

    # Команды только для разработчиков
    def developer_commands
      all_command_classes.select(&:developer_only?)
    end

    # Получить название команды из класса
    # AddCommand -> 'add'
    # NotifyCommand -> 'notify'
    def command_name(command_class)
      command_class.name.underscore.sub(/_command$/, '')
    end

    private

    def patch!(controller)
      Rails.logger.info "Initialize Telegram::CommandRegistry, patch controller #{controller}"
      available_commands.each do |command|
        Rails.logger.info "Patch command #{command}"
        command_class = Telegram::CommandRegistry.get(command)

        controller.define_method "#{command}!" do |*args|
          Rails.logger.info "Call command #{command}"
          command_class.new(self).safe_call(*args)
        end

        command_class.context_method_names.each do |context_method|
          Rails.logger.info "Create context method #{command_class} -> #{context_method}"
          controller.define_method context_method do |*args|
            # Вызываем контекстный метод в экземпляре команды
            command_class
              .new(self)
              .send(context_method, *args)
          end
        end

        command_class.callback_method_names.each do |callback_method|
          Rails.logger.info "Create callback method #{command_class} -> #{callback_method}"
          controller.define_method callback_method do |*args|
            # Вызываем контекстный метод в экземпляре команды
            command_class
              .new(self)
              .send(callback_method, *args)
          end
        end
      end
    end

    def register_command(command_name)
      class_name = "#{command_name.camelize}Command"
      # Используем constantize напрямую, пусть Zeitwerk разбирается с загрузкой
      command_class = class_name.constantize

      # Validate context methods
      (command_class.context_methods || []).each do |method|
        unless command_class.public_instance_methods.include? method
          raise ArgumentError, "Context method '#{method}' does not exist or is not public in #{command_class}"
        end
      end

      @commands[command_name.to_sym] = command_class
      Rails.logger.info "Command registered: #{command_name} -> #{class_name}"
    end
  end
end

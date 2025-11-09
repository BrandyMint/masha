# app/services/telegram/command_registry.rb
class Telegram::CommandRegistry
  class << self
    attr_reader :commands

    def register(command_list)
      @commands ||= {}

      command_list.each do |command_name|
        register_command command_name
      end
    end

    def get(command_name)
      @commands&.dig(command_name.to_sym)
    end

    def available_commands
      @commands&.keys || []
    end

    private

    def register_command command_name
      class_name = "#{command_name.camelize}Command"
      # Используем constantize напрямую, пусть Zeitwerk разбирается с загрузкой
      command_class = class_name.constantize

      # TODO
      #command_class.context_methods.each do |method|
        #method_name = method.to_sym

        #unless command_class.method_defined?(method_name) && command_class.public_method_defined?(method_name)
          #raise ArgumentError, "Context method '#{method_name}' does not exist or is not public in #{command_name}"
        #end
      #end

      @commands[command_name.to_sym] = command_class
      Rails.logger.info "Command registered: #{command_name} -> #{class_name}"
    end
  end
end

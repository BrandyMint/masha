# app/services/telegram/command_registry.rb
class Telegram::CommandRegistry
  class << self
    attr_reader :commands

    def register(command_list)
      @commands ||= {}

      command_list.each do |command_name|
        class_name = "#{command_name.camelize}Command"

        begin
          # Используем constantize напрямую, пусть Zeitwerk разбирается с загрузкой
          command_class = "Telegram::#{class_name}".constantize
          @commands[command_name.to_sym] = command_class
          Rails.logger.info "Command registered: #{command_name} -> Telegram::#{class_name}"
        rescue NameError => e
          Rails.logger.error "Failed to load command: #{command_name} -> Telegram::#{class_name}: #{e.message}"
        end
      end
    end

    def get(command_name)
      @commands&.dig(command_name.to_sym)
    end

    def available_commands
      @commands&.keys || []
    end
  end
end

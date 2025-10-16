# frozen_string_literal: true

# Сервис для сканирования и определения команд Telegram бота
# Автоматически находит все методы команд в контроллерах и классах команд
module Telegram
  class CommandsScanner
    # Основной контроллер бота
    MAIN_CONTROLLER = Telegram::WebhookController

    def initialize
      @commands = {}
    end

    # Сканирует все команды и возвращает список
    def scan_commands(exclude_developer: true)
      scan_main_controller
      scan_command_classes
      commands = format_commands
      exclude_developer ? filter_developer_commands(commands) : commands
    end

    # Возвращает список всех найденных команд (включая developer)
    def all_commands
      scan_commands(exclude_developer: false)
    end

    # Возвращает только пользовательские команды
    def user_commands
      scan_commands(exclude_developer: true)
    end

    # Возвращает только команды разработчиков
    def developer_commands
      all_commands.select { |cmd| cmd[:developer_only] }
    end

    # Фильтрует команды разработчиков
    def filter_developer_commands(commands)
      commands.reject { |cmd| cmd[:developer_only] }
    end

    # Проверяет, является ли метод командой (заканчивается на !)
    def command_method?(method_name)
      method_name.to_s.end_with?('!') && !method_name.to_s.start_with?('_')
    end

    private

    # Сканирует основной контроллер
    def scan_main_controller
      scan_class_methods(MAIN_CONTROLLER)
    end

    # Сканирует все классы команд в Telegram::Commands
    def scan_command_classes
      Dir[Rails.root.join('app/controllers/telegram/commands/*.rb')].each do |file|
        class_name = File.basename(file, '.rb').camelize
        next if class_name == 'BaseCommand'

        command_class = "Telegram::Commands::#{class_name}".constantize
        command_name = class_name.underscore.gsub('_command', '')

        add_command_from_class(command_name, command_class)
      rescue NameError => e
        Rails.logger.warn "Could not load command class #{class_name}: #{e.message}"
      end
    end

    # Сканирует методы класса/модуля
    def scan_class_methods(klass)
      klass.instance_methods(false).each do |method_name|
        next unless command_method?(method_name)

        command_name = method_name.to_s.chomp('!')
        add_command(command_name, klass)
      end
    end

    # Добавляет команду из класса в список
    def add_command_from_class(command_name, command_class)
      @commands[command_name] ||= {
        command: command_name,
        description: get_command_description(command_name),
        source: command_class.name,
        developer_only: developer_command?(command_name)
      }
    end

    # Добавляет команду в список
    def add_command(command_name, source_class)
      @commands[command_name] ||= {
        command: command_name,
        description: get_command_description(command_name),
        source: source_class.name,
        developer_only: developer_command?(command_name)
      }
    end

    # Проверяет, является ли команда для разработчиков
    def developer_command?(command_name)
      %w[users merge].include?(command_name.to_s)
    end

    # Получает описание команды из локализации
    def get_command_description(command_name)
      I18n.t("telegram_bot.commands.#{command_name}")
    rescue StandardError
      command_name.to_s.humanize
    end

    # Форматирует команды для API
    def format_commands
      @commands.values.map do |cmd|
        {
          command: cmd[:command],
          description: cmd[:description],
          developer_only: cmd[:developer_only],
          source: cmd[:source]
        }
      end.sort_by { |cmd| cmd[:command] }
    end
  end
end

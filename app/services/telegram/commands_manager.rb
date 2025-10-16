# frozen_string_literal: true

# Основной сервис для управления командами Telegram бота
# Обеспечивает установку, получение и синхронизацию команд с API
module Telegram
  class CommandsManager
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_reader :bot, :scanner, :errors

    def initialize(bot: nil)
      @bot = bot || Telegram.bot
      @scanner = Telegram::CommandsScanner.new
      @errors = ActiveModel::Errors.new(self)
    end

    # Устанавливает команды в Telegram API
    def set_commands!
      commands = prepare_commands

      if commands.empty?
        add_error(:no_commands, I18n.t('telegram_bot.bot_commands.no_commands_found'))
        return failure_result(I18n.t('telegram_bot.bot_commands.no_commands_found'))
      end

      response = bot.set_my_commands(commands: commands)

      if response['ok']
        Rails.logger.info "Telegram bot commands successfully set: #{commands.map { |c| "/#{c[:command]}" }.join(', ')}"
        success_result(I18n.t('telegram_bot.bot_commands.set_success'))
      else
        error_message = response['description'] || 'Unknown API error'
        add_error(:api_error, error_message)
        failure_result(I18n.t('telegram_bot.bot_commands.set_error', error: error_message))
      end
    rescue StandardError => e
      Bugsnag.notify(e) { |b| b.metadata = { service: 'CommandsManager', action: 'set_commands!' } }
      add_error(:exception, e.message)
      failure_result(I18n.t('telegram_bot.bot_commands.set_error', error: e.message))
    end

    # Возвращает список всех доступных команд (без developer)
    def all_commands
      scanner.user_commands
    end

    # Возвращает все команды включая developer
    def commands_with_developer
      scanner.all_commands
    end

    # Возвращает текущие команды из API Telegram
    def current_commands
      response = bot.get_my_commands
      response['ok'] ? response['result'] : []
    rescue StandardError => e
      Rails.logger.error "Error getting current commands: #{e.message}"
      []
    end

    # Проверяет, нужно ли обновлять команды
    def commands_outdated?
      local_commands = all_commands.map { |cmd| "#{cmd[:command]}:#{cmd[:description]}" }.sort
      remote_commands = current_commands.map { |cmd| "#{cmd['command']}:#{cmd['description']}" }.sort
      local_commands != remote_commands
    end

    # Синхронизирует команды если нужно
    def sync_commands_if_needed
      if commands_outdated?
        set_commands!
      else
        success_result(I18n.t('telegram_bot.bot_commands.commands_equal'))
      end
    end

    # Форматирует команды для вывода
    def format_commands_for_display(commands = nil, include_developer: false)
      commands ||= include_developer ? commands_with_developer : all_commands
      return I18n.t('telegram_bot.bot_commands.no_commands_found') if commands.empty?

      header = I18n.t('telegram_bot.bot_commands.commands_list')
      total = I18n.t('telegram_bot.bot_commands.commands_total', count: commands.count)

      command_list = commands.map do |cmd|
        status = cmd[:developer_only] ? '🔐' : '📱'
        "#{status} /#{cmd[:command]} - #{cmd[:description]}"
      end

      "#{header}\n\n#{command_list.join("\n")}\n\n#{total}"
    end

    # Форматирует только пользовательские команды
    def format_user_commands_for_display
      format_commands_for_display(all_commands, include_developer: false)
    end

    # Форматирует все команды включая developer
    def format_all_commands_for_display
      format_commands_for_display(commands_with_developer, include_developer: true)
    end

    # Валидация команд
    def validate_commands(commands = all_commands)
      validation_errors = []

      commands.each do |cmd|
        # Проверка формата имени команды
        validation_errors << "Invalid command format: #{cmd[:command]}" unless cmd[:command].match?(/\A[a-z][a-z0-9_]*\z/)

        # Проверка длины имени команды
        validation_errors << "Command name too long: #{cmd[:command]}" if cmd[:command].length > 32

        # Проверка длины описания
        validation_errors << "Description too long for command: #{cmd[:command]}" if cmd[:description].length > 256
      end

      # Проверка общего количества команд
      validation_errors << "Too many commands: #{commands.count} (max 100)" if commands.count > 100

      validation_errors
    end

    private

    # Подготавливает команды для API
    def prepare_commands
      commands = all_commands

      # Валидация
      validation_errors = validate_commands(commands)
      if validation_errors.any?
        add_error(:validation, validation_errors.join(', '))
        return []
      end

      commands
    end

    # Добавляет ошибку
    def add_error(attribute, message)
      errors.add(attribute, message)
    end

    # Возвращает успешный результат
    def success_result(message)
      {
        success: true,
        message: message,
        commands_count: all_commands.count,
        commands: all_commands
      }
    end

    # Возвращает результат с ошибкой
    def failure_result(message)
      {
        success: false,
        message: message,
        errors: errors.full_messages,
        commands_count: all_commands.count,
        commands: all_commands
      }
    end
  end
end

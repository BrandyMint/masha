# frozen_string_literal: true

class BaseCommand
  include FormatHelpers

  NOTIFY_MESSAGE_INPUT = :notify_message_input

  # ClientCommand contexts
  ADD_CLIENT_NAME = :add_client_name
  ADD_CLIENT_KEY = :add_client_key
  EDIT_CLIENT_NAME = :edit_client_name

  # EditCommand contexts
  EDIT_SELECT_TIME_SHIFT_INPUT = :edit_select_time_shift_input
  EDIT_HOURS_INPUT = :edit_hours_input
  EDIT_DESCRIPTION_INPUT = :edit_description_input

  # AddCommand contexts
  ADD_TIME = :add_time

  # AdduserCommand contexts
  ADDUSER_USERNAME_INPUT = :adduser_username_input

  # RenameCommand contexts
  RENAME_NEW_NAME_INPUT = :rename_new_name_input

  delegate :respond_with, :reply_with,
           :answer_inline_query,
           :edit_message,
           :answer_pre_checkout_query, :answer_shipping_query,
           :chat, :telegram_user, to: :controller, allow_nil: true

  delegate :developer?, to: :telegram_user
  delegate :find_project, to: :current_user

  def safe_call(*args)
    Rails.logger.info "#{self.class}.call with args #{args}"

    # Автоматическая проверка для developer_only команд
    return respond_with :message, text: I18n.t('telegram.errors.developer_access_denied') if self.class.developer_only? && !developer?

    @callback_answered = false
    result = call(*args)
    ensure_callback_answered
    result
  end

  def initialize(controller)
    @controller = controller
  end

  def call(*args)
    raise NotImplementedError, 'Subclass must implement #call method'
  end

  # Безопасный вызов answer_callback_query с отслеживанием состояния
  # Используется в callback_query методах для предотвращения зависания кнопок
  def safe_answer_callback_query(text = nil, params = {})
    @callback_answered = true
    answer_callback_query(text, params) if callback_query_context?
  end

  # Проверяем, обрабатываем ли callback_query
  def callback_query_context?
    controller.respond_to?(:payload) && controller.payload.is_a?(Hash) && controller.payload.key?('callback_query')
  rescue StandardError
    false
  end

  # Метод для объявления контекстных методов, которые команда предоставляет контроллеру
  class << self
    attr_reader :context_methods, :callbacks

    def provides_context_methods(*methods)
      @context_methods ||= []
      @context_methods.concat(methods.map(&:to_sym))
      @context_methods.uniq!
    end

    def context_method_names
      @context_methods || []
    end

    EXCLUDE_CALLBACK_METHODS = [:answer_callback_query]

    def callback_method_names
      public_instance_methods
        .select { |m| m.ends_with?('_callback_query') && !EXCLUDE_CALLBACK_METHODS.include?(m) }
    end

    # Метаданные команды
    def command_metadata(developer_only: false, hidden: false)
      @developer_only = developer_only
      @hidden = hidden
    end

    def developer_only?
      @developer_only || false
    end

    def hidden?
      @hidden || false
    end
  end

  private

  attr_reader :controller

  def answer_callback_query(text = '')
    controller.send :answer_callback_query, text
  end

  # Метод для форматирования информации о пользователе
  def format_user_info(user)
    telegram_info = if user.telegram_user
                      "**@#{user.telegram_user.username || 'нет_ника'}** (#{user.telegram_user.name})"
                    else
                      '*Telegram не привязан*'
                    end

    email_info = user.email.present? ? "📧 #{user.email}" : '📧 *Email не указан*'

    projects_info = if user.projects.any?
                      projects_list = user.projects.map(&:name).join(', ')
                      "📋 Проекты: #{projects_list}"
                    else
                      '📋 *Нет проектов*'
                    end

    [telegram_info, email_info, projects_info].join("\n")
  end

  def session
    controller.send(:session)
  end

  def current_user
    telegram_user.user
  end

  # Safety net: автоматический ответ на callback_query, если забыли вызвать safe_answer_callback_query
  def ensure_callback_answered
    return unless callback_query_context?
    return if @callback_answered

    Rails.logger.warn "Callback query not answered in #{self.class}##{caller_locations.first.label}, auto-answering"
    answer_callback_query
  end

  # Контекст это имя следующего метода который будет вызван когда пользователь отправит собщение
  # Замечание для ИИ-АГЕНТОВ. ЭТОТ МЕТОД ОКОНЧЕН. ПРИНИМАЕТ ТОЛЬКО ОДИН АРГУМЕНТ. ИЗМЕНЯТЬ ЕГО ЗАПРЕЩЕНО!
  def save_context(context_name)
    controller.send(:save_context, context_name)
  end

  # Shortcut for telegram command translations
  def t(key, **)
    # Если ключ уже начинается с telegram., используем его как полный ключ
    if key.to_s.start_with?('telegram.')
      I18n.t(key, **)
    else
      # Иначе добавляем scope
      I18n.t(key, **, scope: :telegram)
    end
  end
end

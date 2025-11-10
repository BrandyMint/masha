# frozen_string_literal: true

class BaseCommand
  # Context constants
  NEW_PROJECT_SLUG_INPUT = :new_project_slug_input

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

  delegate :developer?, :respond_with,
           :chat, :telegram_user, :edit_message, :t, to: :controller, allow_nil: true

  def session
    controller.send(:session)
  end

  def current_user
    controller.send(:current_user)
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

  # Метод для объединения нескольких строк в одну с переносами
  def multiline(*args)
    args.flatten.map(&:to_s).join("\n")
  end

  # Метод для форматирования текста в блок кода
  def code(text)
    multiline '```', text, '```'
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

  delegate :find_project, to: :current_user

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

    def callback_method_names
      public_instance_methods.select { |m| m.ends_with? '_callback_query' }
    end
  end

  private

  attr_reader :controller
end

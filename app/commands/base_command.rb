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

  delegate :developer?, :respond_with,
           :multiline, :code, :help_message, :format_user_info,
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

  delegate :find_project, to: :current_user

  # Метод для объявления контекстных методов, которые команда предоставляет контроллеру
  class << self
    attr_reader :context_methods, :callbacks

    def provides_context_methods(*methods)
      @context_methods ||= []

      methods.each do |method|
        method_name = method.to_sym

        #unless method_defined?(method_name) && public_method_defined?(method_name)
          #raise ArgumentError, "Context method '#{method_name}' does not exist or is not public in #{name}"
        #end
      end

      @context_methods.concat(methods.map(&:to_sym))
      @context_methods.uniq!
    end

    def context_method_names
      @context_methods || []
    end

    def callback_method_names
      public_methods.select { |m| m.ends_with? '_callback_query' }
    end
  end

  private

  attr_reader :controller
end

# frozen_string_literal: true

class BaseCommand
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
    attr_reader :context_methods

    def provides_context_methods(*methods)
      @context_methods ||= []
      @context_methods.concat(methods.map(&:to_sym))
      @context_methods.uniq!
    end

    def context_method_names
      @context_methods || []
    end
  end

  private

  attr_reader :controller
end

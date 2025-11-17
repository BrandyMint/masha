# frozen_string_literal: true

module Telegram
  class TimeShiftOperationsService
    include Telegram::Concerns::ValidationsConcern

    attr_reader :user

    def initialize(user)
      @user = user
    end

    # Добавить запись времени
    def add_time_entry(project_slug, hours, description = nil)
      project_service = Telegram::ProjectService.new(user)
      project = project_service.find_project(project_slug)

      hours_float = hours.to_s.tr(',', '.').to_f

      # Проверяем на предупреждения
      warning_message = nil
      if hours_float > 12
        warning_message = " ⚠️ Много часов за день (#{hours_float})"
      elsif hours_float < 0.5
        warning_message = " ℹ️ Мало часов (#{hours_float})"
      end

      project.time_shifts.create!(
        date: Time.zone.today,
        hours: hours_float,
        description: description || '',
        user: user
      )

      # Формируем сообщение
      message_parts = ["✅ Отметили #{hours_float}ч в проекте #{project.slug}"]
      message_parts << warning_message if warning_message
      message_parts << "📝 #{description}" if description.present?

      message_parts.join("\n")
    rescue StandardError => e
      Rails.logger.error "Error adding time entry: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      "❌ Ошибка при добавлении времени: #{e.message}\nПопробуйте еще раз или свяжитесь с поддержкой."
    end

    # Получить текущую запись времени для редактирования
    def edit_time_shift(telegram_session)
      return nil unless telegram_session&.type == :edit

      time_shift_id = telegram_session[:time_shift_id]
      user.time_shifts.includes(:project).find_by(id: time_shift_id)
    end

    private

    # Реализация метода из FormattingConcern
    def find_project_by_id(project_id)
      project_service = Telegram::ProjectService.new(user)
      project_service.find_project(project_id)
    end
  end
end

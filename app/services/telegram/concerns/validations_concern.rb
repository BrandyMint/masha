# frozen_string_literal: true

module Telegram
  module Concerns
    module ValidationsConcern
      extend ActiveSupport::Concern

      private

      # Проверяет является ли строка числом (с плавающей точкой)
      def numeric?(str)
        return false unless str.is_a?(String)

        str.match?(/\A\d+([.,]\d+)?\z/)
      end

      # Валидирует и конвертирует часы в float
      def validate_hours(hours_str)
        hours = hours_str.to_s.tr(',', '.').to_f
        hours >= 0.1 ? hours : nil
      end

      # Валидирует описание
      def validate_description(description)
        return nil if description == '-'
        return nil if description && description.length > 1000

        description
      end

      # Проверяет формат времени
      def time_format?(str)
        return false unless str.is_a?(String)

        # Проверяем формат времени
        return false unless str.match?(/\A\d+([.,]\d+)?\z/)

        # Конвертируем и проверяем диапазон
        hours = str.tr(',', '.').to_f
        hours.positive? && hours <= 100.0 # Более широкая проверка, диапазон проверим отдельно
      end

      # Проверяет находится ли время вне допустимого диапазона
      def time_out_of_range?(str)
        return false unless str.is_a?(String)

        hours = str.tr(',', '.').to_f
        hours < 0.1 || hours > 24.0
      end
    end
  end
end

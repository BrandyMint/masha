# frozen_string_literal: true

module Telegram
  module Concerns
    module FormattingConcern
      extend ActiveSupport::Concern

      private

      # Объединяет несколько строк в одну с переносами
      def multiline(*args)
        args.compact.join("\n")
      end

      # Построить текст изменений для подтверждения
      def build_changes_text(time_shift, field, new_values)
        case field
        when 'project'
          new_project = find_project_by_id(new_values['project_id'])
          return ['Ошибка: новый проект не найден'] unless new_project

          ["Проект: #{time_shift.project.name} → #{new_project.name}"]
        when 'hours'
          ["Часы: #{time_shift.hours} → #{new_values['hours']}"]
        when 'description'
          old_desc = time_shift.description || '(нет)'
          new_desc = new_values['description'] || '(нет)'
          ["Описание: #{old_desc} → #{new_desc}"]
        else
          ['Ошибка: неизвестное поле для редактирования']
        end
      end

      # Вспомогательный метод для поиска проекта по ID (может быть переопределен в классах)
      def find_project_by_id(project_id)
        # Этот метод должен быть реализован в классе, который включает этот concern
        raise NotImplementedError, 'find_project_by_id должен быть реализован в включающем классе'
      end
    end
  end
end

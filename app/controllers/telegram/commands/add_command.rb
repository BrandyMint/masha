# frozen_string_literal: true

module Telegram
  module Commands
    class AddCommand < BaseCommand
      def call(project_slug = nil, hours = nil, *description)
        if project_slug.nil?
          show_project_selection
          return
        end

        add_time_to_project(project_slug, hours, description.join(' '))
      end

      private

      def show_project_selection
        save_context :add_callback_query
        respond_with :message,
                     text: 'Выберите проект, в котором отметить время:',
                     reply_markup: {
                       resize_keyboard: true,
                       inline_keyboard:
                       current_user.available_projects.alive
                                   .map { |p| { text: p.name, callback_data: "select_project:#{p.slug}" } }
                                   .each_slice(3).to_a
                     }
      end

      def add_time_to_project(project_slug, hours, description)
        project = find_project(project_slug)

        if project.present?
          project.time_shifts.create!(
            date: Time.zone.today,
            hours: hours.to_s.tr(',', '.').to_f,
            description: description,
            user: current_user
          )

          message = "Отметили в #{project.name} #{hours} часов"
        else
          message = "Не найден такой проект '#{project_slug}'. Вам доступны: #{current_user.available_projects.alive.join(', ')}"
        end

        respond_with :message, text: message
      end
    end
  end
end

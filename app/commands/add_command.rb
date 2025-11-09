# frozen_string_literal: true

class AddCommand < BaseCommand
  provides_context_methods :add_time

  public

  def call(project_slug = nil, hours = nil, *description)
    if project_slug.nil?
      show_project_selection
    else
      add_time_to_project(project_slug, hours, description.join(' '))
    end
  end

  def select_project_callback_query(project_slug)
    save_context :add_time
    project = find_project project_slug
    controller.telegram_session = TelegramSession.add_time(project_id: project.id)
    edit_message :text,
                 text: "Вы выбрали проект #{project.slug}, теперь укажите время и через пробел комментарий (12 делал то-то)"
  end

  def add_time(hours, *description)
    data = controller.telegram_session_data
    project = current_user.available_projects.find(data['project_id']) || raise('Не указан проект')
    description = description.join(' ')
    project.time_shifts.create!(
      date: Time.zone.today,
      hours: hours.to_s.tr(',', '.').to_f,
      description: description,
      user: current_user
    )

    controller.clear_telegram_session
    respond_with :message, text: "Отметили в #{project.name} #{hours} часов"
  end

  private

  def show_project_selection
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

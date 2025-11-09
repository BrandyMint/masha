# frozen_string_literal: true

class AttachCommand < BaseCommand
  def call(project_slug = nil, *)
    if project_slug.blank?
      message = 'Укажите первым аргументом проект, к которому присоединяете этот чат'
    elsif chat['id'].to_i.negative?
      project = find_project(project_slug)
      project.update telegram_chat_id: chat['id']
      message = "Установили этот чат основным в проекте #{project}"
    else
      message = 'Присоединять можно только чаты, личную переписку нельзя'
    end
    respond_with :message, text: message
  end
end

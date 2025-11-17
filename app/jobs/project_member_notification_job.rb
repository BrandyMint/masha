# frozen_string_literal: true

class ProjectMemberNotificationJob < ApplicationJob
  queue_as :default

  def perform(project_id:, new_member_id:)
    project = Project.find(project_id)
    new_member = User.find(new_member_id)

    # Find all project members with Telegram accounts, excluding the new member
    members_to_notify = project.users
                               .joins(:telegram_user)
                               .where.not(id: new_member_id)

    return if members_to_notify.empty?

    # Format message about the new member
    message = format_new_member_message(project, new_member)

    # Send notification to each member
    members_to_notify.find_each do |member|
      TelegramNotificationJob.perform_later(
        user_id: member.telegram_user.id,
        message: message
      )
    end
  end

  private

  def format_new_member_message(project, new_member)
    telegram_info = ''
    name_info = ''

    if new_member.telegram_user
      telegram_info = new_member.telegram_user.telegram_nick
      name_info = new_member.telegram_user.name
    else
      telegram_info = new_member.email || 'Неизвестный пользователь'
      name_info = ''
    end

    role = new_member.membership_of(project)&.role || 'неопределена'

    message = "👥 В проект \"#{project.slug}\" добавлен новый участник:\n"
    message += "• #{telegram_info}"
    message += " (#{name_info})" if name_info.present?
    message += "\n• Роль: #{role_translation(role)}"

    message
  end

  def role_translation(role)
    case role.to_s
    when 'owner'
      'владелец'
    when 'viewer'
      'наблюдатель'
    when 'member'
      'участник'
    else
      role.to_s
    end
  end
end

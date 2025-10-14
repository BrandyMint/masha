# frozen_string_literal: true

class ProjectRenameService
  include RenameConfig

  attr_reader :result

  def initialize
    @result = { success: false, message: nil }
  end

  def call(user, project, new_name, project_slug = nil)
    # Валидация входных данных
    return error_result(format(MESSAGES[:empty_name])) if new_name.blank?

    # Проверка проекта (если передан slug вместо объекта)
    if project.blank? && project_slug.present?
      project = Project.find_by(slug: project_slug)
      return error_result(format(MESSAGES[:project_not_found], project_slug)) unless project
    end

    return error_result('Проект не указан') if project.blank?

    # Валидация названия
    return error_result(MESSAGES[:too_short]) if new_name.length < MIN_LENGTH
    return error_result(MESSAGES[:too_long]) if new_name.length > MAX_LENGTH

    # Проверка прав доступа
    return error_result(MESSAGES[:no_permission]) unless can_rename?(user, project)

    # Проверка уникальности названия
    return error_result(MESSAGES[:name_taken]) if Project.where.not(id: project.id).exists?(name: new_name)

    # Переименование и результат
    perform_rename(project, new_name)
  end

  def success_message(old_name, old_slug, new_name, new_slug)
    multiline(
      MESSAGES[:success_header],
      format(MESSAGES[:old_name_label], old_name, old_slug),
      format(MESSAGES[:new_name_label], new_name, new_slug)
    )
  end

  def manageable_projects(user)
    user.available_projects.alive.joins(:memberships)
        .where(memberships: { user: user, role_cd: 0 })
  end

  private

  def can_rename?(user, project)
    membership = user.membership_of(project)
    membership&.owner?
  end

  def perform_rename(project, new_name)
    old_name = project.name
    old_slug = project.slug

    project.update!(name: new_name)

    success_result(success_message(old_name, old_slug, project.name, project.slug))
  rescue ActiveRecord::RecordInvalid => e
    error_result(format(MESSAGES[:rename_error], e.message))
  end

  def success_result(message)
    @result = { success: true, message: message }
  end

  def error_result(message)
    @result = { success: false, message: message }
  end

  def multiline(*args)
    args.flatten.map(&:to_s).join("\n")
  end
end

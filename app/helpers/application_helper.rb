module ApplicationHelper
  ROLES_LABELS = {
    :admin => 'important',
    :owner => 'warning',
    :viewer => 'info',
    :member => 'success'
  }

  def available_projects
    if current_user.is_root?
      Project.ordered
    else
      current_user.projects.ordered
    end
  end

  def user_roles user
    buffer = ''
    # TODO Показывтаь все роли на классы и глобальные
    buffer << role_label(:admin) if user.is_root?
    buffer.html_safe
  end

  def role_label role, active = true
    return unless role.present?

    role = role.role if role.is_a? Membership

    label_class = active ? "label-#{ROLES_LABELS[role]}" : ''
    content_tag :span, I18n.t(role, :scope => [:roles]), :class => "label #{label_class}"
  end

  def user_roles_of_project user, project
    buffer = ''
    Project::ROLES.each do |role|
      buffer << role_label(role) if user.has_role? role, project
    end
    buffer.html_safe
  end

  def change_role_link user, project, role
    active = user.has_role?(role, project)
    if active
      link_to remove_role_project_url(project, :user_id => user.id, :role => role), :method => :delete do
        role_label role, active
      end
    else
      link_to set_role_project_url(project, :user_id => user.id, :role => role), :method => :post do
        role_label role, active
      end
    end
  end
end

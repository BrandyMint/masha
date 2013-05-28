module ApplicationHelper
  ROLES_LABELS = {
    :admin => 'important',
    :owner => 'warning',
    :timekeeper => 'info',
    :time_enterer => 'success'
  }
  def user_roles user
    buffer = ''
    # TODO Показывтаь все роли на классы и глобальные
    buffer << role_label(:admin) if user.has_role? :admin
    buffer.html_safe
  end

  def role_label role, active = true
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
    if user.has_role? role, project
      link_to remove_role_user_url(user, :role => role, :project_id => project.id), :method => :delete do
        role_label role, user.has_role?(role, project)
      end
    else
      link_to add_role_user_url(user, :role => role, :project_id => project.id), :method => :post do
        role_label role, user.has_role?(role, project)
      end
    end
  end
end

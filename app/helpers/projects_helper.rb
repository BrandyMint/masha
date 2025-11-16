# frozen_string_literal: true

module ProjectsHelper
  def edit_project_link(project)
    link_to 'Переименовать', edit_project_path(project), class: 'btn btn-default' if current_user.can_update? project
  end

  def projects_link
    link_to '&larr; список проектов'.html_safe, projects_url
  end

  def change_project_status_link(project)
    return unless current_user.can_create?(Membership.new(project: project))

    if project.active
      if project.time_shifts.any?
        link_to t('project.archivate'), archivate_project_path(project), method: :put,
                                                                         class: 'btn btn-default btn-mini'
      else
        link_to t('project.remove'), project_path(project), method: :delete, class: 'btn btn-danger btn-mini'
      end
    else
      link_to t('project.activate'), activate_project_path(project), method: :put, class: 'btn btn-default btn-mini'
    end
  end
end

module ProjectsHelper

	def edit_project_link project
		if current_user.can_update? project
			link_to edit_project_path(project) do
				icon :edit
			end
		end
	end

  def projects_link
    link_to '&larr; список проектов'.html_safe, projects_url
  end

  def change_project_status_link project
    if project.active
      link_to t('project.archivate'), archivate_project_path(@project), :method=>:put, :class => 'btn btn-default btn-mini'
    else
      link_to t('project.activate'), activate_project_path(@project), :method=>:put, :class => 'btn btn-default btn-mini'
    end
  end

end

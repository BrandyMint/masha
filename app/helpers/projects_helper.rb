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

end

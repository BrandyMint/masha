module ProjectsHelper

	def edit_project_link project
		if current_user.can_update? project
			link_to edit_project_path(project) do
				icon :edit
			end
		end
	end

end

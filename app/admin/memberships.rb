ActiveAdmin.register Membership do
  index do
    column :project, :sortable => :project_id
    column :user, :sortable => :user_id
    column :role, :sortable => :role_cd
    actions
  end

end

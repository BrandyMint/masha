ActiveAdmin.register Membership do
  index do
    column :project, :sortable => :project_id
    column :user, :sortable => :user_id
    column :role, :sortable => :role_cd
    actions
  end

  form do |f|
    f.inputs do
      f.input :project
      f.input :user
      f.input :role_cd, :as => :select, :collection => Membership.roles_collection, :required => true
    end
    f.actions

  end

end

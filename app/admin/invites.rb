ActiveAdmin.register Invite do

  menu :label => proc{ I18n.t("active_admin.invites") }, parent: 'Люди'

  index do
    column :id
    column :email
    column :user
    column :role
    column :project
    actions
  end

end



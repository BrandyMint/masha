ActiveAdmin.register Authentication do

	menu :priority => 4, :label => proc{ I18n.t("active_admin.authentications") }

  index do
    column :user
    column :provider
    column :id
    column :username
    column :nickname
    column :email
  end

end

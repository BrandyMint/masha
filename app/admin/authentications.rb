ActiveAdmin.register Authentication do

	menu :label => proc{ I18n.t("active_admin.authentications") }, parent: 'Люди'

  index do
    column :user
    column :provider
    column :id
    column :username
    column :nickname
    column :email
  end

end

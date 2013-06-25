ActiveAdmin.register Authentication do

  index do
    column :user
    column :provider
    column :id
    column :username
    column :nickname
    column :email
  end

end

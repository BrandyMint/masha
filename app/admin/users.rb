ActiveAdmin.register User do

  index do
    column :avatar do |user|
      image_tag UserDecorator.decorate(user).avatar_url
    end
    column :name
    column :nickname
    column :email
    column :is_root
    column :authentications do |user|
      return if user.authentications.empty?
      link_to "authentications #{user.authentications.count}", admin_authentications_url(:q => { :user_id_in=>user.id })
    end
    actions
  end

end

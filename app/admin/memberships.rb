# frozen_string_literal: true

ActiveAdmin.register Membership do
  menu priority: 5, label: proc { I18n.t('active_admin.membership') }

  index do
    column :project, sortable: :project_id
    column :user, sortable: :user_id
    column :role, sortable: :role_cd
    actions
  end

  form do |f|
    f.inputs do
      f.input :project
      f.input :user
      f.input :role_cd, as: :select, collection: Membership.roles, required: true
    end
    f.actions
  end
end

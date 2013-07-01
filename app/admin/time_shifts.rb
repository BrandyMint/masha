ActiveAdmin.register TimeShift do
  index do
    column :updated_at
    column :date
    column :project, :sortable => :project_id
    column :user, :sortable => :user_id
    column :hours
    column :description
    actions
  end


  form do |f|
    f.inputs "Details" do
      f.input :project
      f.input :user
      f.input :date
      f.input :hours, :min => 0.1, :max => 24
    end
    f.inputs "Content" do
      f.input :description
    end
    f.actions
  end

end

ActiveAdmin.register TimeShift do

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

ActiveAdmin.register Project do

  index do
    column :name
    column :memberships do |p|
      ul :class => :horizontal do
        li link_to "#{p.memberships.count} members", admin_memberships_url(:q=>{:project_id_in=>p.id})
        li ' / '
        li link_to 'add', new_admin_membership_url(:membership => { :project_id=>p.id, :role => :member})
      end
    end
    column :total_hours do |p|
      link_to human_hours(p.time_shifts.sum(:hours)), admin_time_shifts_url(:q=>{:project_id_in=>p.id})
    end
    actions
  end

  form do |f|
    f.inputs "Details" do
      f.input :name
    end
    f.actions
  end


end

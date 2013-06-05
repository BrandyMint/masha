require 'csv'

#0 "Date",
#1 "Last Name",
#2 "Given Name",
#3 "Person ID",
#4 "Project",
#5 "Hours",
#6 "Description"
#

if User.exists?
  raise 'В продакшене не работаею' if Rails.env.production?
  User.destroy_all
end

CSV.foreach "#{Rails.root}/db/pivotal.csv" do |row|
  date, last_name, given_name, person_id, project_id, hours, description = row

  description = 'no description' if description.blank?

  next if date == 'Date'
  begin

    project = Project.where(:name=>project_id).first || Project.create!(:name=>project_id)

    user_name = row.slice(1,2) * ' '

    user = User.where(:pivotal_person_id=>person_id).first || User.create!(:name=>user_name, :pivotal_person_id => person_id)

    project.time_shifts.create! :user => user, :hours => hours,
      :description => description, :date => date
  rescue StandardError => err
    binding.pry
    puts err.inspect
  end
end

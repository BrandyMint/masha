require 'csv'
# 0 "Date",
# 1 "Last Name",
# 2 "Given Name",
# 3 "Person ID",
# 4 "Project",
# 5 "Hours",
# 6 "Description"
#

namespace :masha do
  namespace :import do
    desc 'Импортируем данные из пивотала (file_to_import=./pivotal.csv)'
    task pivotal: :environment do
      file_to_import = ENV['file_to_import'] or fail 'Не указан файл для импорта (file_to_import)'

      CSV.foreach file_to_import do |row|
        date, last_name, given_name, person_id, project_id, hours, description = row

        description = 'no description' if description.blank?

        next if date == 'Date'
        begin

          project = Project.where(name: project_id).first || Project.create!(name: project_id)

          fail "No such project #{project_id}" unless project.present?

          user_name = row.slice(1, 2) * ' '

          user = User.where(pivotal_person_id: person_id).first
          # || User.create!(:name=>user_name, :pivotal_person_id => person_id)
          #
          fail "No such person #{person_id} #{user_name}" unless user.present?

          attrs = { user: user, hours: hours, description: description, date: date }

          project.time_shifts.create! attrs unless project.time_shifts.where(attrs).first.present?

        rescue StandardError => err
          puts err.inspect
        end
      end
    end
  end
end

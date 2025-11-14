# frozen_string_literal: true

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
      file_to_import = ENV.fetch('file_to_import', nil) or raise 'Не указан файл для импорта (file_to_import)'

      CSV.foreach file_to_import do |row|
        date, _, _, person_id, project_id, hours, description = row

        description = 'no description' if description.blank?

        next if date == 'Date'

        begin
          project = Project.where(name: project_id).first || Project.create!(name: project_id)

          raise "No such project #{project_id}" if project.blank?

          user_name = row.slice(1, 2) * ' '

          user = User.where(pivotal_person_id: person_id).first
          # || User.create!(:name=>user_name, :pivotal_person_id => person_id)
          #
          raise "No such person #{person_id} #{user_name}" if user.blank?

          attrs = { user: user, hours: hours, description: description, date: date }

          project.time_shifts.create! attrs if project.time_shifts.where(attrs).first.blank?
        rescue StandardError => e
          puts e.inspect
        end
      end
    end
  end
end

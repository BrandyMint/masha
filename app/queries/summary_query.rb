class SummaryQuery
  attr_accessor :days, :projects, :total_by_date

  attr_reader :period

  attr_accessor :available_projects, :available_users

  def initialize period=nil
    @available_users = nil
    @available_projects = nil
    @period = period=='month' ? 'month' : 'week'
  end

  def perform
    scope = TimeShift.includes(:project, :user)

    scope = scope.where :project_id => available_projects_ids
    scope = scope.where :user_id => available_users_ids

    projects_ids = []

    @total_by_date = {}

    @days = dates.map do |date|
      res = scope.group(:project_id).where(date: date).sum(:hours)
      projects_ids += res.keys

      res.each_pair do |project_id, hours|
        @total_by_date[date]||=0
        @total_by_date[date]+=hours
      end

      {
        date: date,
        projects: res
      }
    end

    @projects = projects_ids.uniq.sort.map { |id| Project.find id }

  end

  def to_csv
    CSV.generate(col_sep: ';') do |csv|
      csv << ['date'] + @projects + ['total']
      @days.each do |day|
        row = [day[:date]]
        @projects.each do |project|
          row << (day[:projects][project.id].blank? ? '-' : day[:projects][project.id])
        end
        csv << row.push(@total_by_date[day[:date]])
      end
    end
  end

  private

  def dates
   @dates ||= begin
                today = Date.today
                if @period == 'month'
                  start_date = today.at_beginning_of_month
                  start_date = start_date.prev_month if today-start_date<10
                else
                  start_date = today.at_beginning_of_week
                  start_date = start_date.prev_week if today-start_date<3
                end

                (start_date..Date.today).to_a.reverse
              end
  end

  def available_projects_ids
    @available_projects.map &:id
  end

  def available_users_ids
    @available_users.map &:id
  end

end

class SummaryQuery
  attr_accessor :days, :projects, :total_by_date

  attr_accessor :available_projects, :available_users

  def initialize
    @available_users = User.all
    @available_projects = Project.all
  end

  def perform
    scope = TimeShift.includes(:project, :user)

    scope = scope.where :project_id => available_projects_ids
    scope = scope.where :user_id => available_users_ids

    dates = scope.group(:date).order('date desc').limit(5).pluck(:date)

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

  def available_projects_ids
    @available_projects.map &:id
  end

  def available_users_ids
    @available_users.map &:id
  end

end

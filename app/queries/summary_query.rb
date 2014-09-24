class SummaryQuery
  attr_accessor :days, :columns, :total_by_date

  attr_reader :period, :group_by

  attr_accessor :available_projects, :available_users

  def initialize period=nil
    @available_users = nil
    @available_projects = nil
    @period = period=='month' ? 'month' : 'week'
    @group_by = :project
  end

  def group_by= value
    if value.to_s == 'project'
      @group_by = :project
    else
      @group_by = :user
    end
  end

  def perform
    ids = []

    @total_by_date = {}

    @days = dates.map do |date|
      res = grouped_scope date
      ids += res.keys

      res.each_pair do |id, hours|
        @total_by_date[date]||=0
        @total_by_date[date]+=hours
      end

      {
        date: date,
        columns: res
      }
    end

    @columns = ids.uniq.sort.map { |id| item_find id }.compact

  end

  def to_csv
    CSV.generate(col_sep: ';') do |csv|
      csv << ['date'] + @columns + ['total']
      @days.each do |day|
        row = [day[:date]]
        @columns.each do |column|
          row << (day[:columns][column.id].blank? ? '-' : day[:columns][column.id])
        end
        csv << row.push(@total_by_date[day[:date]])
      end
    end
  end

  private

  def scope
    s = TimeShift.includes(:project, :user)

    s = s.where :project_id => available_projects_ids
    s.where :user_id => available_users_ids
  end

  def grouped_scope date
    scope.group(group_column).where(date: date).sum(:hours)
  end

  def group_column
    @group_by == :project ? :project_id : :user_id
  end

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

  def item_find id
    klass = @group_by == :project ? Project : User
    klass.find id
  rescue => e
    Airbrake.notify e, context: { group_by: @group_by }
  end

  def available_projects_ids
    @available_projects.map &:id
  end

  def available_users_ids
    @available_users.map &:id
  end

end

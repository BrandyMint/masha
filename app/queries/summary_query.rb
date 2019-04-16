class SummaryQuery
  attr_accessor :days, :columns, :total_by_date, :total_by_column, :total

  def self.for_user(user, group_by: nil, period: [])
    new(users: user.available_users, projects: user.available_projects, period: period, group_by: group_by)
  end

  # @params period = [] or :month, or :weel
  # @param group_by = :project :user

  def initialize(users: [], projects: [], period: [], group_by: :project)
    @users    = users
    @projects = projects
    @group_by = group_by || :project
    @period   = build_period period
  end

  def perform
    ids = []
    @total_by_date = {}
    @total_by_column = {}
    @days = period.map do |date|
      res = grouped_scope date
      ids += res.keys

      res.each_pair do |_id, hours|
        @total_by_date[date] ||= 0
        @total_by_date[date] += hours
      end
      {
        date: date,
        columns: res
      }
    end

    @columns = ids.uniq.sort.map { |id| item_find id }.compact

    @total = scope.sum(:hours)

    @columns.each do |column|
      str_column = column.to_s
      @total_by_column[str_column] = summary_by_column column
    end

    {
      columns: columns,
      total: total,
      total_by_date: total_by_date,
      total_by_column: total_by_column,
      days: days,
      group_by: group_by,
      period: period
    }
  end

  def summary_by_column(column)
    scope.where(group_column => column).sum(:hours)
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

  attr_reader :users, :group_by, :projects, :period

  def scope
    s = TimeShift.includes(:project, :user)
    s = s.where project_id: projects_ids
    s.where user_id: users_ids
  end

  def grouped_scope(date)
    scope.group(group_column).where(date: date).sum(:hours)
  end

  def grouped_by_column_scope
    scope.group(group_column)
  end

  def group_column
    group_by == :project ? :project_id : :user_id
  end

  def build_period(period)
    today = Date.today
    if period.is_a? Enumerable
      return period
    elsif period.to_sym == :month
      start_date = today.at_beginning_of_month
      start_date = start_date.prev_month if today - start_date < 10
    elsif period.to_sym == :week
      start_date = today.at_beginning_of_week
      start_date = start_date.prev_week if today - start_date < 3
    else
      raise "Unknown period #{period}"
    end

    (start_date..today).to_a.reverse
  end

  def item_find(id)
    klass = group_by == :project ? Project : User
    klass.find id
  rescue => e
    Bugsnag.notify e do |b|
      b.meta_data = { group_by: group_by }
    end
  end

  def projects_ids
    if projects.is_a? ActiveRecord::AssociationRelation
      projects.pluck :id
    else
      projects.map &:id
    end
  end

  def users_ids
    if users.is_a? ActiveRecord::AssociationRelation
      users.pluck :id
    else
      users.map &:id
    end
  end
end

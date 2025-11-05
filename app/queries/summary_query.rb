# frozen_string_literal: true

class SummaryQuery
  attr_accessor :total

  def self.for_user(user, group_by: nil, period: nil)
    parsed_period = PeriodParser.parse(period)
    new(users: user.available_users, projects: user.available_projects, period: parsed_period, group_by: group_by)
  end

  # @params period = [] or :month, or :weel
  # @param group_by = :project :user

  def initialize(users: [], projects: [], period: [], group_by: :project)
    @users    = users
    @projects = projects
    @group_by = group_by || :project
    @period   = build_period period
  end

  def list_by_days
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

  def projects_to_users_matrix
    matrix = { total: {} }
    projects = Set.new
    users = Set.new
    scope.each do |time_shift|
      projects << time_shift.project
      users << time_shift.user
      project_row = (matrix[time_shift.project] ||= {})
      project_row[time_shift.user] ||= 0
      project_row[time_shift.user] += time_shift.hours
      project_row[:total] ||= 0
      project_row[:total] += time_shift.hours

      all_project_row = matrix[:total]
      all_project_row[time_shift.user] ||= 0
      all_project_row[time_shift.user] += time_shift.hours
      all_project_row[:total] ||= 0
      all_project_row[:total] += time_shift.hours
    end
    {
      matrix: matrix,
      period: period,
      projects: projects,
      users: users,
      days: days
    }
  end

  def to_csv
    CSV.generate(col_sep: ';') do |csv|
      csv << ['date'] + columns + ['total']
      days.each do |day|
        row = [day[:date]]
        columns.each do |column|
          row << (day[:columns][column.id].presence || '-')
        end
        csv << row.push(total_by_date[day[:date]])
      end
    end
  end

  private

  attr_reader :users, :group_by, :projects, :period

  def total
    @total ||= scope.sum(:hours)
  end

  def summary_by_column(column)
    scope.where(group_column => column).sum(:hours)
  end

  def scope
    TimeShift
      .includes(:project, :user)
      .where(project_id: projects_ids)
      .where(user_id: users_ids)
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
    case period
    when 'week' then (Date.today - 6)..Date.today
    when 'month' then Date.today.beginning_of_month..Date.today
    when 'last_month' then (Date.today - 1.month).beginning_of_month..(Date.today - 1.month).end_of_month
    when 'last_week' then (Date.today - 1.week).beginning_of_week..(Date.today - 1.week).end_of_week
    when 'last_day' then (Date.today - 1.day)..(Date.today - 1.day)
    when 'day' then Date.today..Date.today
    when Hash then build_period_from_hash(period)
    else
      # Обратная совместимость для старых форматов
      today = Time.zone.today
      if period.is_a?(Enumerable)
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
  end

  def build_period_from_hash(period_hash)
    case period_hash[:type]
    when :date then period_hash[:date]..period_hash[:date]
    when :month then period_hash[:date].beginning_of_month..period_hash[:date].end_of_month
    when :range then period_hash[:start_date]..period_hash[:end_date]
    when :month_range then period_hash[:start_date]..period_hash[:end_date].end_of_month
    end
  end

  def item_find(id)
    klass = group_by == :project ? Project : User
    klass.find id
  rescue StandardError => e
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

  def build_totals
    ids = Set.new
    @total_by_date = {}
    @days = period.map do |date|
      res = grouped_scope date
      ids += res.keys

      res.each_pair do |_id, hours|
        @total_by_date[date] ||= 0
        @total_by_date[date] += hours
      end
      {
        date: date.is_a?(Date) ? date : Date.parse(date),
        columns: res
      }
    end

    @columns = ids.uniq.sort.map { |id| item_find id }.compact
    @total_by_column = {}
    @columns.each do |column|
      str_column = column.to_s
      @total_by_column[str_column] = summary_by_column column
    end
  end

  def days
    build_totals unless @days
    @days
  end

  def columns
    build_totals unless @columns
    @columns
  end

  def total_by_date
    build_totals unless @total_by_date
    @total_by_date
  end

  def total_by_column
    build_totals unless @total_by_column
    @total_by_column
  end

  def users_ids
    if users.is_a? ActiveRecord::AssociationRelation
      users.pluck :id
    else
      users.map &:id
    end
  end
end

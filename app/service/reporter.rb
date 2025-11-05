# frozen_string_literal: true

require 'terminal-table'

class Reporter
  def list_by_days(user, period: :week, group_by: :project)
    tableize_list_by_days SummaryQuery.for_user(user, period: period, group_by: group_by).list_by_days
  end

  def projects_to_users_matrix(user, period = 'week')
    tableize_projects_to_users_matrix SummaryQuery.for_user(user, period: period).projects_to_users_matrix
  end

  private

  def tableize_projects_to_users_matrix(result)
    title = build_period_title(result[:period])
    columns = [:total] + result[:projects].to_a
    table = Terminal::Table.new title: title do |t|
      t << [''] + columns.map(&:to_s)
      t << :separator

      (result[:users].to_a + [:total]).each do |user|
        t << [user] + columns.map { |c| result[:matrix].fetch(c, {}).fetch(user, '·') }
      end
    end

    table.columns.count.times { |i| table.align_column(i, :right) }
    table.to_s
  end

  def build_period_title(period)
    case period
    when 'week' then "#{Date.today - 6} - #{Date.today}"
    when 'month' then Date.today.strftime("%B %Y")
    when 'last_month' then (Date.today - 1.month).strftime("%B %Y")
    when 'last_week' then "Last week"
    when 'last_day' then (Date.today - 1.day).strftime("%Y-%m-%d")
    when 'day' then Date.today.strftime("%Y-%m-%d")
    when Hash
      case period[:type]
      when :date then period[:date].strftime("%Y-%m-%d")
      when :month then period[:date].strftime("%B %Y")
      when :range then "#{period[:end_date]} - #{period[:start_date]}"
      when :month_range then "#{period[:end_date].strftime("%B %Y")} - #{period[:start_date].strftime("%B %Y")}"
      end
    else
      if period.respond_to?(:empty?) && period.empty?
        'All days'
      elsif period.respond_to?(:first) && period.respond_to?(:last)
        # Check if it's a full month range
        if period.first == period.first.beginning_of_month && period.last == period.first.end_of_month.end_of_month
          period.first.strftime("%B %Y")
        # Check if current month period
        elsif period.last == Date.today && period.first == Date.today.beginning_of_month
          Date.today.strftime("%B %Y")
        else
          "#{period.last} - #{period.first}"
        end
      elsif period.is_a?(String)
        period
      else
        period.to_s
      end
    end
  end

  def tableize_list_by_days(result)
    table = Terminal::Table.new do |t|
      t << %i[date total] + result[:columns].map(&:name)
      t << :separator

      result[:days].each do |day|
        row = []
        row << day[:date].to_s
        row << result[:total_by_date][day[:date]] || 0

        row += result[:columns].map { |r| day[:columns][r.id] || '·' }
        t << row
      end

      t << :separator
      t << ['All days', result[:total_by_date].values.compact.sum] + result[:columns].map { |c|
        result[:total_by_column][c.to_s]
      }
    end

    table.columns.count.times { |i| table.align_column(i, :right) }
    table.to_s
  end
end

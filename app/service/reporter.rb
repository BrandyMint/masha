# frozen_string_literal: true

require 'terminal-table'

class Reporter
  def list_by_days(user, period: :week, group_by: :project)
    tableize_list_by_days SummaryQuery.for_user(user, period: period, group_by: group_by).list_by_days
  end

  def projects_to_users_matrix(user, period = :week)
    tableize_projects_to_users_matrix SummaryQuery.for_user(user, period: period).projects_to_users_matrix
  end

  private

  def tableize_projects_to_users_matrix(result)
    title = result[:period].empty? ? 'All days' : "#{result[:period].last} - #{result[:period].first}"
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

require 'terminal-table'

class Reporter
  def perform(user, period: :week, group_by: :project)
    result = SummaryQuery.for_user(user, period: period, group_by: group_by).perform
    tableize_result result
  end

  private

  def tableize_result(result)
    table = Terminal::Table.new do |t|
      t << [:date, :total] + result[:columns].map(&:name)
      t << :separator

      result[:days].each do |day|
        row = []
        row << day[:date].to_s
        row << result[:total_by_date][day[:date]]

        row += result[:columns].map { |r| day[:columns][r.id] || '·' }
        t << row
      end

      t << :separator
      t << ['All days', result[:total_by_column].values.compact.sum] + result[:columns].map { |c| result[:total_by_column][c.to_s] }
    end

    table.to_s
  end
end

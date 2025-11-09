# frozen_string_literal: true

class PeriodParser
  SUPPORTED_RELATIVE = %w[day week month last_month last_week last_day].freeze

  def self.parse(arg)
    return 'week' if arg.nil?

    case arg
    when *SUPPORTED_RELATIVE then arg
    when /^\d{4}-\d{2}$/
      date = Date.parse("#{arg}-01")
      validate_date_range(date, date.end_of_month)
      { type: :month, date: date }
    when /^\d{4}-\d{2}-\d{2}$/
      date = Date.parse(arg)
      validate_date_range(date, date)
      { type: :date, date: date }
    when /^\d{4}-\d{2}-\d{2}\.\.\d{4}-\d{2}-\d{2}$/ then parse_date_range(arg)
    when /^\d{4}-\d{2}\.\.\d{4}-\d{2}$/ then parse_month_range(arg)
    else raise ArgumentError, 'Invalid period format'
    end
  rescue Date::Error => e
    raise ArgumentError, "Invalid date format: #{e.message}"
  end

  def self.parse_date_range(range_str)
    start_date, end_date = range_str.split('..').map { |d| Date.parse(d) }
    validate_date_range(start_date, end_date)
    { type: :range, start_date: start_date, end_date: end_date }
  end

  def self.parse_month_range(range_str)
    start_month, end_month = range_str.split('..').map { |m| Date.parse("#{m}-01") }
    validate_date_range(start_month, end_month.end_of_month)
    { type: :month_range, start_date: start_month, end_date: end_month }
  end

  def self.validate_date_range(start_date, end_date)
    raise ArgumentError, 'Start date cannot be after end date' if start_date > end_date

    raise ArgumentError, 'Period cannot exceed 365 days' if (end_date - start_date).to_i > 365

    return unless start_date < Date.today - 730 # ~2 years

    raise ArgumentError, 'Data older than 2 years is not available'
  end
end

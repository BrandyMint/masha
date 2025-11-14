# frozen_string_literal: true

# Unified report command supporting flexible period, filters, and format options.
# Replaces /day, /summary, /hours commands with single comprehensive interface.
#
# Usage:
#   /report                                    # Today, summary format
#   /report week                               # Current week, summary
#   /report month project:work-project         # Month filtered by project
#   /report yesterday detailed                 # Yesterday with descriptions
#   /report 2025-01-01:2025-01-31 detailed     # Date range, detailed
class ReportCommand < BaseCommand
  HELP_SECTIONS = {
    'periods' => :periods_help,
    'filters' => :filters_help,
    'options' => :options_help,
    'examples' => :examples_help,
    'main' => :main_help
  }.freeze
  def call(*args)
    # Check for help request
    return show_help if args.first == 'help'

    # Parse command parameters
    params = parse_params(args)

    # Build report data
    builder = ReportBuilder.new(
      user: current_user,
      period: params[:period],
      filters: params[:filters]
    )
    report_data = builder.build

    # Format output
    formatter = ReportFormatter.new(report_data, format: params[:format])
    text = formatter.format_report

    # Send response
    respond_with :message, text: code(text), parse_mode: :Markdown
  end

  private

  def parse_params(args)
    params = {
      period: :today,
      filters: {},
      format: :summary
    }

    return params if args.empty?

    # Join args to handle split text
    text = args.join(' ')

    # Extract format option (detailed)
    if text.match?(/\bdetailed\b/i)
      params[:format] = :detailed
      text = text.gsub(/\bdetailed\b/i, '').strip
    end

    # Extract project filter
    if (match = text.match(/project:([a-z0-9_-]+)/i))
      params[:filters][:project] = match[1]
      text = text.gsub(/project:[a-z0-9_-]+/i, '').strip
    end

    # Extract projects filter (multiple)
    if (match = text.match(/projects:([\w\s,_-]+)/i))
      params[:filters][:projects] = match[1].strip
      text = text.gsub(/projects:[\w\s,_-]+/i, '').strip
    end

    # Parse period from remaining text
    period_text = text.strip.downcase

    params[:period] = parse_period(period_text) unless period_text.empty?

    params
  end

  def parse_period(text)
    case text
    when 'today'
      :today
    when 'yesterday'
      :yesterday
    when 'week'
      :week
    when 'month'
      :month
    when 'quarter'
      :quarter
    when /^\d{4}-\d{2}-\d{2}$/
      # Single date format YYYY-MM-DD
      text
    when /^\d{4}-\d{2}-\d{2}:\d{4}-\d{2}-\d{2}$/
      # Date range format YYYY-MM-DD:YYYY-MM-DD
      text
    else
      # Fallback to today for invalid input
      :today
    end
  end

  def show_help
    help_formatter = ReportHelpFormatter.new
    text = help_formatter.main_help
    keyboard = help_formatter.main_keyboard

    respond_with :message,
                 text: text,
                 reply_markup: keyboard
  end

  def report_callback_query(data = nil)
    data ||= callback_data
    return unless data&.start_with?('report_help_')

    section = data.sub('report_help_', '')
    return unless HELP_SECTIONS.key?(section)

    help_formatter = ReportHelpFormatter.new
    text = help_formatter.send(HELP_SECTIONS[section])
    keyboard = help_formatter.navigation_keyboard(section)

    edit_message :text,
                 text: text,
                 reply_markup: keyboard
  end

  def callback_data
    controller.callback_query.data
  rescue StandardError
    nil
  end
end

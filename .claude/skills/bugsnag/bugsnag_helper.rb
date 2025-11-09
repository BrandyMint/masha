#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

class BugsnagHelper
  API_BASE_URL = 'https://api.bugsnag.com'

  def initialize
    @api_key = ENV['BUGSNAG_DATA_API_KEY']
    @project_id = ENV['BUGSNAG_PROJECT_ID']

    validate_credentials
  end

  def list_errors(limit: 20, status: nil, severity: nil)
    uri = build_uri("/projects/#{@project_id}/errors")
    uri.query = URI.encode_www_form({
      limit: limit,
      status: status,
      severity: severity
    }.compact)

    response = make_request(uri)
    format_errors_list(response)
  end

  def get_error_details(error_id)
    uri = build_uri("/projects/#{@project_id}/errors/#{error_id}")
    response = make_request(uri)
    format_error_details(response)
  end

  def resolve_error(error_id)
    # Try different endpoints and methods
    endpoints_and_methods = [
      { method: :put, endpoint: "/projects/#{@project_id}/errors" },
      { method: :post, endpoint: "/projects/#{@project_id}/errors" },
      { method: :put, endpoint: "/projects/#{@project_id}/errors/bulk" },
      { method: :post, endpoint: "/projects/#{@project_id}/errors/bulk" },
      { method: :put, endpoint: "/projects/#{@project_id}/errors/#{error_id}" }
    ]

    put_data = {
      error_ids: [error_id],
      operation: "resolve"
    }.to_json

    endpoints_and_methods.each do |config|
      uri = build_uri(config[:endpoint])

      puts "🔍 Trying #{config[:method].upcase} request to #{uri}"
      puts "🔍 Request body: #{put_data}"

      begin
        if config[:method] == :put
          response = make_put_request(uri, put_data)
        else
          response = make_post_request(uri, put_data)
        end

        puts "✅ Success with #{config[:method].upcase} #{config[:endpoint]}"
        return format_resolution_response(response, error_id)
      rescue => e
        puts "❌ Failed with #{config[:method].upcase} #{config[:endpoint]}: #{e.message}"
        next
      end
    end

    raise "All endpoints failed to resolve error #{error_id}"
  end

  def get_error_events(error_id, limit: 10)
    uri = build_uri("/projects/#{@project_id}/errors/#{error_id}/events")
    uri.query = URI.encode_www_form(limit: limit)

    response = make_request(uri)
    format_events_list(response)
  end

  def analyze_errors
    errors = list_errors(limit: 50)
    analyze_error_patterns(errors)
  end

  private

  def validate_credentials
    unless @api_key && @project_id
      raise "Missing required environment variables: BUGSNAG_DATA_API_KEY and BUGSNAG_PROJECT_ID"
    end
  end

  def build_uri(path)
    URI("#{API_BASE_URL}#{path}")
  end

  def make_request(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "token #{@api_key}"
    request['Content-Type'] = 'application/json'
    # request['X-Version'] = '2020-07-01' # Bugsnag works without version header

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise "Bugsnag API error: #{response.code} - #{response.message}"
    end

    JSON.parse(response.body)
  end

  def make_patch_request(uri, body)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Patch.new(uri)
    request['Authorization'] = "token #{@api_key}"
    request['Content-Type'] = 'application/json'
    # request['X-Version'] = '2020-07-01' # Bugsnag works without version header
    request.body = body

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise "Bugsnag API error: #{response.code} - #{response.message}"
    end

    response
  end

  def make_put_request(uri, body)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Put.new(uri)
    request['Authorization'] = "token #{@api_key}"
    request['Content-Type'] = 'application/json'
    # request['X-Version'] = '2020-07-01' # Bugsnag works without version header
    request.body = body

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise "Bugsnag API error: #{response.code} - #{response.message}"
    end

    response
  end

  def make_post_request(uri, body)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "token #{@api_key}"
    request['Content-Type'] = 'application/json'
    # request['X-Version'] = '2020-07-01' # Bugsnag works without version header
    request.body = body

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise "Bugsnag API error: #{response.code} - #{response.message}"
    end

    response
  end

  def format_errors_list(errors_data)
    errors = errors_data.is_a?(Array) ? errors_data : errors_data['errors'] || []

    output = ["📋 Найдено ошибок: #{errors.length}\n"]

    errors.each do |error|
      status_emoji = case error['status']
                     when 'open' then '❌'
                     when 'resolved' then '✅'
                     when 'ignored' then '🚫'
                     else '❓'
                     end

      severity_emoji = case error['severity']
                       when 'error' then '🔴'
                       when 'warning' then '🟡'
                       when 'info' then '🔵'
                       else '⚪'
                       end

      output << "#{status_emoji} #{severity_emoji} **#{error['error_class']}** (#{error['events']} событий)"
      output << "   ID: `#{error['id']}`"
      output << "   Первое появление: #{format_time(error['first_seen'])}"
      output << "   Последнее: #{format_time(error['last_seen'])}"
      output << "   URL: #{error['url']}" if error['url']
      output << ""
    end

    output.join("\n")
  end

  def format_error_details(error_data)
    error = error_data['error'] || error_data

    output = []
    output << "🔍 **Детали ошибки:** #{error['error_class']}"
    output << ""
    output << "**Основная информация:**"
    output << "• ID: `#{error['id']}`"
    output << "• Статус: #{error['status']}"
    output << "• Критичность: #{error['severity']}"
    output << "• Событий: #{error['events']}"
    output << "• Пользователи затронуто: #{error['users']}"
    output << ""

    if error['first_seen'] && error['last_seen']
      output << "**Временные рамки:**"
      output << "• Первое появление: #{format_time(error['first_seen'])}"
      output << "• Последнее: #{format_time(error['last_seen'])}"
      output << ""
    end

    output << "**Контекст:**"
    output << "• App Version: #{error.dig('app', 'version') || 'N/A'}"
    output << "• Release Stage: #{error.dig('app', 'releaseStage') || 'N/A'}"
    output << "• Language: #{error['language'] || 'N/A'}"
    output << "• Framework: #{error['framework'] || 'N/A'}"
    output << ""

    if error['url']
      output << "**URL:** #{error['url']}"
      output << ""
    end

    if error['message']
      output << "**Сообщение:**"
      output << "```"
      output << error['message']
      output << "```"
      output << ""
    end

    output
  end

  def format_events_list(events_data)
    events = events_data['events'] || []

    output = ["📊 События ошибки (#{events.length}):\n"]

    events.each_with_index do |event, index|
      output << "**Событие #{index + 1}:**"
      output << "• ID: `#{event['id']}`"
      output << "• Время: #{format_time(event['receivedAt'])}"
      output << "• App Version: #{event['app']['releaseStage'] || 'N/A'}"
      output << "• OS: #{event['device']['osName'] || 'N/A'} #{event['device']['osVersion'] || ''}"

      if event['user']
        output << "• Пользователь: #{event['user']['name'] || event['user']['id'] || 'N/A'}"
      end

      if event['message']
        output << "• Сообщение: #{event['message']}"
      end

      output << ""
    end

    output.join("\n")
  end

  def format_resolution_response(response, error_id)
    if response.is_a?(Net::HTTPSuccess)
      "✅ Ошибка `#{error_id}` успешно отмечена как выполненная!"
    else
      "❌ Не удалось отметить ошибку `#{error_id}` как выполненную: #{response.code} - #{response.message}"
    end
  end

  def analyze_error_patterns(errors)
    critical_errors = errors.select { |e| e['severity'] == 'error' && e['status'] == 'open' }
    warnings = errors.select { |e| e['severity'] == 'warning' && e['status'] == 'open' }

    output = ["📈 **Анализ ошибок в проекте:**\n"]

    output << "🔴 **Критичные ошибки (#{critical_errors.length}):**"
    if critical_errors.any?
      critical_errors.first(5).each do |error|
        output << "• #{error['errorClass']} - #{error['eventsCount']} событий (ID: #{error['id']})"
      end
    else
      output << "• Нет критичных ошибок!"
    end
    output << ""

    output << "🟡 **Предупреждения (#{warnings.length}):**"
    if warnings.any?
      warnings.first(5).each do |error|
        output << "• #{error['errorClass']} - #{error['eventsCount']} событий (ID: #{error['id']})"
      end
    else
      output << "• Нет предупреждений!"
    end
    output << ""

    # Частые паттерны ошибок
    error_classes = errors.group_by { |e| e['errorClass'] }
    frequent_errors = error_classes.select { |klass, errs| errs.length > 1 }

    if frequent_errors.any?
      output << "🔄 **Повторяющиеся паттерны:**"
      frequent_errors.each do |error_class, errors|
        total_events = errors.sum { |e| e['eventsCount'] }
        output << "• #{error_class}: #{errors.length} экземпляров, #{total_events} событий"
      end
    end

    output.join("\n")
  end

  def format_time(timestamp)
    return 'N/A' unless timestamp
    Time.parse(timestamp).strftime('%Y-%m-%d %H:%M:%S UTC')
  rescue
    timestamp
  end
end
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'open-uri'
require 'net/http'

# Скрипт для генерации человекочитаемого changelog через Claude API
# Использование: bin/generate_claude_changelog.rb [from_tag] [to_tag]

class ClaudeChangelogGenerator
  def initialize(api_key = nil)
    @api_key = api_key || ENV['ANTHROPIC_API_KEY']
    raise 'ANTHROPIC_API_KEY не найден' unless @api_key
  end

  def generate_changelog(from_tag = nil, to_tag = 'HEAD')
    commits = get_commits(from_tag, to_tag)
    return "Нет коммитов для анализа" if commits.empty?

    prompt = build_prompt(commits, to_tag)
    response = call_claude_api(prompt)
    parse_response(response)
  end

  private

  def get_commits(from_tag, to_tag)
    range = if from_tag
               "#{from_tag}..#{to_tag}"
             else
               # Ищем предыдущий тег
               tags = `git tag --sort=-version:refname`.split("\n")
               current_tag = to_tag == 'HEAD' ? `git describe --tags --abbrev=0`.strip : to_tag
               current_index = tags.index(current_tag)
               previous_tag = current_index ? tags[current_index + 1] : nil
               previous_tag ? "#{previous_tag}..#{to_tag}" : '--max-count=50'
             end

    raw_commits = `git log #{range} --pretty=format:"%H|%s|%b|%an|%ad" --date=short --no-merges`
    return [] if raw_commits.empty?

    raw_commits.split("\n").map do |line|
      hash, subject, body, author, date = line.split('|', 5)
      {
        hash: hash[0..6],
        subject: subject.strip,
        body: body.strip,
        author: author.strip,
        date: date.strip
      }
    end
  end

  def build_prompt(commits, version)
    version_name = version == 'HEAD' ? `git describe --tags --abbrev=0`.strip : version

    <<~PROMPT
      Проанализируй следующие коммиты и создай профессиональный changelog на русском языке для релиза #{version_name}.

      Коммиты:
      #{format_commits(commits)}

      Требования к changelog:
      1. Напиши на естественном русском языке, как будто ты разработчик проекта
      2. Сгруппируй изменения по логическим категориям:
         - ✨ Новый функционал (новые возможности)
         - 🐛 Исправления (исправленные ошибки)
         - 🔧 Улучшения (улучшения существующего)
         - 🏗️ Внутренние изменения (рефакторинг, технические улучшения)
         - 📚 Документация
      3. Используй понятные описания вместо технических терминов
      4. Добавь краткое вступление с основной темой релиза
      5. Используй эмодзи для наглядности
      6. Если коммит не важен для пользователей, опусти его
      7. Пример хорошего описания: "Исправили проблему с отображением времени в Safari" вместо "fix: time display issue"

      Начни с заголовка: "## Что нового в версии #{version_name}"
    PROMPT
  end

  def format_commits(commits)
    commits.map do |commit|
      "- **#{commit[:subject]}** (#{commit[:hash]}, #{commit[:author]}, #{commit[:date]})\n  #{commit[:body] unless commit[:body].empty?}"
    end.join("\n")
  end

  def call_claude_api(prompt)
    uri = URI('https://api.anthropic.com/v1/messages')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['x-api-key'] = @api_key
    request['anthropic-version'] = '2023-06-01'

    request_body = {
      model: 'claude-3-sonnet-20240229',
      max_tokens: 2000,
      messages: [{
        role: 'user',
        content: prompt
      }]
    }.to_json

    request.body = request_body

    response = http.request(request)
    unless response.code == '200'
      puts "Ошибка API: #{response.code} #{response.body}"
      return nil
    end

    response.body
  end

  def parse_response(response_body)
    return "Ошибка генерации changelog" unless response_body

    begin
      parsed = JSON.parse(response_body)
      parsed['content']&.first&.dig('text') || "Ошибка парсинга ответа"
    rescue JSON::ParserError => e
      puts "Ошибка парсинга JSON: #{e}"
      "Ошибка обработки ответа от Claude"
    end
  end
end

# Запуск скрипта
if __FILE__ == $0
  from_tag = ARGV[0]
  to_tag = ARGV[1] || 'HEAD'

  begin
    generator = ClaudeChangelogGenerator.new
    changelog = generator.generate_changelog(from_tag, to_tag)
    puts changelog
  rescue => e
    puts "Ошибка: #{e.message}"
    exit 1
  end
end
#!/usr/bin/env ruby
# frozen_string_literal: true

# Скрипт для генерации changelog на основе git коммитов
# Использование: bin/generate_changelog.rb [from_tag] [to_tag]

require 'json'

class ChangelogGenerator
  def initialize(from_tag = nil, to_tag = nil)
    @from_tag = from_tag
    @to_tag = to_tag || 'HEAD'
  end

  def generate
    puts "## Изменения в #{current_version}"
    puts

    commits.each do |commit|
      category = categorize_commit(commit[:message])
      puts "#{category_emoji(category)} **#{category_name(category)}:** #{commit[:message]} (#{commit[:hash]})"
    end

    puts
    puts "---"
    puts "*Автоматически сгенерировано #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}*"
  end

  private

  def current_version
    @to_tag == 'HEAD' ? current_tag_from_git : @to_tag
  end

  def current_tag_from_git
    `git describe --tags --abbrev=0`.strip
  end

  def previous_tag
    return @from_tag if @from_tag

    # Ищем предыдущий тег
    tags = `git tag --sort=-version:refname`.split("\n")
    current_index = tags.index(current_version)
    current_index ? tags[current_index + 1] : nil
  end

  def commits
    range = if previous_tag
               "#{previous_tag}..#{@to_tag}"
             else
               '--max-count=50'
             end

    raw_commits = `git log #{range} --pretty=format:"%H|%s" --no-merges`
    raw_commits.split("\n").map do |line|
      hash, message = line.split('|', 2)
      {
        hash: hash[0..6], # короткий хеш
        message: message.strip
      }
    end
  end

  def categorize_commit(message)
    case message.downcase
    when /feat|feature|add|новый|добавить/
      :feature
    when /fix|bug|исправ|починить/
      :fix
    when /refactor|refact/
      :refactor
    when /doc|документация|readme/
      :docs
    when /test|spec|тест/
      :test
    when /lint|style|rubocop/
      :style
    when /chore|bump|версия|v\d+/
      :chore
    else
      :other
    end
  end

  def category_emoji(category)
    case category
    when :feature then '✨'
    when :fix then '🐛'
    when :refactor then '🔧'
    when :docs then '📚'
    when :test then '✅'
    when :style then '🎨'
    when :chore then '🔧'
    else '📝'
    end
  end

  def category_name(category)
    case category
    when :feature then 'Новый функционал'
    when :fix then 'Исправления'
    when :refactor then 'Рефакторинг'
    when :docs then 'Документация'
    when :test then 'Тесты'
    when :style then 'Стиль'
    when :chore then 'Обслуживание'
    else 'Прочее'
    end
  end
end

# Запуск скрипта
if __FILE__ == $0
  from_tag = ARGV[0]
  to_tag = ARGV[1]

  generator = ChangelogGenerator.new(from_tag, to_tag)
  generator.generate
end
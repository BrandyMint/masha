# frozen_string_literal: true

module Telegram
  class ProjectService
    include Telegram::Concerns::ValidationsConcern

    attr_reader :user

    def initialize(user)
      @user = user
    end

    # Найти проект по slug или ID
    def find_project(key)
      if key.is_a?(Integer)
        user.available_projects.alive.find_by(id: key)
      else
        user.available_projects.alive.find_by(slug: key)
      end
    end

    # Найти проект с опечатками (расстояние Левенштейна)
    def find_project_fuzzy(slug)
      # Ищем проект с опечатками
      available_projects = user.available_projects.alive

      available_projects.find do |project|
        levenshtein_distance(slug.downcase, project.slug.downcase) <= 2
      end
    end

    # Получить список доступных slugs проектов
    def available_projects_slugs
      @available_projects_slugs ||= user.available_projects.alive.pluck(:slug)
    end

    # Найти похожие проекты
    def find_similar_projects(slug)
      available_slugs = available_projects_slugs
      similar = available_slugs.select do |available_slug|
        levenshtein_distance(slug.downcase, available_slug.downcase) <= 2
      end
      similar.first(5) # Ограничиваем количество предложений
    end

    private

    # Простая реализация расстояния Левенштейна
    def levenshtein_distance(str1, str2)
      matrix = Array.new(str1.length + 1) { Array.new(str2.length + 1) }

      (0..str1.length).each { |i| matrix[i][0] = i }
      (0..str2.length).each { |j| matrix[0][j] = j }

      (1..str1.length).each do |i|
        (1..str2.length).each do |j|
          cost = str1[i - 1] == str2[j - 1] ? 0 : 1
          matrix[i][j] = [
            matrix[i - 1][j] + 1,     # deletion
            matrix[i][j - 1] + 1,     # insertion
            matrix[i - 1][j - 1] + cost # substitution
          ].min
        end
      end

      matrix[str1.length][str2.length]
    end
  end
end

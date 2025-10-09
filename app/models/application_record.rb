# frozen_string_literal: true

# Базовый абстрактный класс для всех моделей приложения с настройкой ransackable_attributes для поиска.
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.ransackable_attributes(_auth_object = nil)
    attribute_names
  end
end

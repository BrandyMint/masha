class ApplicationRecord < ActiveRecord::Base
  def self.ransackable_attributes(_auth_object = nil)
    attribute_names
  end
end

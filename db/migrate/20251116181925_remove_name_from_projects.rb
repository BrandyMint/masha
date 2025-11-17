# frozen_string_literal: true

class RemoveNameFromProjects < ActiveRecord::Migration[8.0]
  def change
    remove_column :projects, :name, :string
  end
end

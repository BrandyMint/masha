# frozen_string_literal: true

class NullifyUsersName < ActiveRecord::Migration[8.0]
  def change
    change_column_null :users, :name, true
  end
end

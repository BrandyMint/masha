# frozen_string_literal: true

class AllowNullifyTimeShiftDescription < ActiveRecord::Migration[8.0]
  def change
    change_column_null :time_shifts, :description, true
  end
end

class AddDateToTimeShifts < ActiveRecord::Migration
  def change
    add_column :time_shifts, :date, :date, :null => false
  end
end

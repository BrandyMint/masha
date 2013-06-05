class AddDateToTimeShifts < ActiveRecord::Migration
  def up
    TimeShift.delete_all
    add_column :time_shifts, :date, :date, :null => false
    rename_column :time_shifts, :minutes, :hours
    change_column :time_shifts, :hours, :decimal, :null => false
    add_column :time_shifts, :description, :text, :null => false
  end

  def down
    remove_column :time_shifts, :date
    remove_column :time_shifts, :description
    rename_column :time_shifts, :hours, :minutes
  end
end

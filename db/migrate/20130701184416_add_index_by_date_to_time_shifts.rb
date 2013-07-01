class AddIndexByDateToTimeShifts < ActiveRecord::Migration
  def change
    add_index :time_shifts, :date, :order => { :date => :desc }
  end
end

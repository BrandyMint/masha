class CreateTimeShifts < ActiveRecord::Migration
  def change
    create_table :time_shifts do |t|
      t.references :project, index: true, :null => false
      t.references :user, index: true, :null => false
      t.integer :minutes, :null => false

      t.timestamps
    end
  end
end

class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name, :null => false
      t.boolean :is_root, :null => false, :default => false

      t.timestamps
    end
  end
end

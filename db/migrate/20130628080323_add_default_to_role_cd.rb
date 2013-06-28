class AddDefaultToRoleCd < ActiveRecord::Migration
  def change
    change_column :memberships, :role_cd, :integer, :default => 2
  end
end

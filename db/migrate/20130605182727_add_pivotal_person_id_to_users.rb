class AddPivotalPersonIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :pivotal_persion_id, :integer
  end
end

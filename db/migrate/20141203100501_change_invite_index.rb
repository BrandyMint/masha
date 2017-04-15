class ChangeInviteIndex < ActiveRecord::Migration
  def change
    remove_index :invites, :email
    add_index :invites, [:email, :project_id], unique: true
  end
end

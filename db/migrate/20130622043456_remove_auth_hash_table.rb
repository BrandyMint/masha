class RemoveAuthHashTable < ActiveRecord::Migration
  def change
    drop_table :add_auth_hash_to_users

    add_column :authentications, :auth_hash, :text
  end
end

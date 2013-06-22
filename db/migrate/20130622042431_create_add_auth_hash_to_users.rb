class CreateAddAuthHashToUsers < ActiveRecord::Migration
  def change
    create_table :add_auth_hash_to_users do |t|
      t.text :auth_hash

      t.timestamps
    end
  end
end

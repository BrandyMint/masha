class RolifyCreateRoles < ActiveRecord::Migration
  def change
    create_table(:roles) do |t|
      t.string :name, :null => false
      t.references :resource, :polymorphic => true

      t.timestamps
    end

    create_table(:users_roles, :id => false) do |t|
      t.references :user, :null => false
      t.references :role, :null => false
    end

    add_index :roles, :name
    add_index :roles, [ :name, :resource_type, :resource_id ], :unique => true
    add_index :users_roles, [ :user_id, :role_id ], :unique => true
  end
end

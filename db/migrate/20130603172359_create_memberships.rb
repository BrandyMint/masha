class CreateMemberships < ActiveRecord::Migration
  def change
    create_table :memberships do |t|
      t.references :user, index: true
      t.references :project, index: true
      t.integer :role_cd, :null => false

      t.timestamps
    end

    add_index :memberships, [:user_id, :project_id], :unique => true

    remove_column :projects, :owner_id

    drop_table :roles
    drop_table :users_roles
  end
end

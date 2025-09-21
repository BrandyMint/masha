class AddMissingForeignKeys < ActiveRecord::Migration[8.0]
  def change
    # Add foreign key for authentications -> users
    add_foreign_key :authentications, :users, on_delete: :restrict

    # Add foreign keys for invites
    add_foreign_key :invites, :users, on_delete: :restrict
    add_foreign_key :invites, :projects, on_delete: :restrict

    # Add foreign keys for memberships
    add_foreign_key :memberships, :users, on_delete: :restrict
    add_foreign_key :memberships, :projects, on_delete: :restrict

    # Add foreign keys for time_shifts
    add_foreign_key :time_shifts, :users, on_delete: :restrict
    add_foreign_key :time_shifts, :projects, on_delete: :restrict

    # Add foreign key for users -> telegram_users
    add_foreign_key :users, :telegram_users, on_delete: :restrict
  end
end

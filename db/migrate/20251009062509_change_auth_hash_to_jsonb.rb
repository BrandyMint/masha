# frozen_string_literal: true

class ChangeAuthHashToJsonb < ActiveRecord::Migration[8.0]
  def up
    # Add new jsonb column
    add_column :authentications, :auth_hash_jsonb, :jsonb

    # Remove old column and rename new one
    remove_column :authentications, :auth_hash
    rename_column :authentications, :auth_hash_jsonb, :auth_hash
  end

  def down
    # Add back text column
    add_column :authentications, :auth_hash_text, :text

    # Remove jsonb column and rename text one
    remove_column :authentications, :auth_hash
    rename_column :authentications, :auth_hash_text, :auth_hash
  end
end

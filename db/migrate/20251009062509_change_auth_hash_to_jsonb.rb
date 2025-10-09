# frozen_string_literal: true

class ChangeAuthHashToJsonb < ActiveRecord::Migration[8.0]
  def up
    # Add new jsonb column
    add_column :authentications, :auth_hash_jsonb, :jsonb

    # Migrate data from YAML to JSON
    Authentication.find_each do |auth|
      if auth.auth_hash.is_a?(String)
        # Parse YAML string
        hash = YAML.safe_load(auth.auth_hash, permitted_classes: [Symbol, Time, ActiveSupport::TimeWithZone])
        auth.update_column(:auth_hash_jsonb, hash)
      elsif auth.auth_hash.is_a?(Hash)
        # Already a hash, just copy
        auth.update_column(:auth_hash_jsonb, auth.auth_hash)
      end
    end

    # Remove old column and rename new one
    remove_column :authentications, :auth_hash
    rename_column :authentications, :auth_hash_jsonb, :auth_hash
  end

  def down
    # Add back text column
    add_column :authentications, :auth_hash_text, :text

    # Convert JSON back to YAML
    Authentication.find_each do |auth|
      auth.update_column(:auth_hash_text, auth.auth_hash.to_yaml) if auth.auth_hash.present?
    end

    # Remove jsonb column and rename text one
    remove_column :authentications, :auth_hash
    rename_column :authentications, :auth_hash_text, :auth_hash
  end
end

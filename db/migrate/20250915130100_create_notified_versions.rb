# frozen_string_literal: true

class CreateNotifiedVersions < ActiveRecord::Migration[8.0]
  # rubocop:disable  Rails/CreateTableWithTimestamps
  def change
    create_table :notified_versions do |t|
      t.string :version, null: false

      t.timestamp :created_at, null: false
    end

    add_index :notified_versions, :version, unique: true
  end
  # rubocop:enable  Rails/CreateTableWithTimestamps
end

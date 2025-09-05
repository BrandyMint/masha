# frozen_string_literal: true

class AddTelegramUsernameToInvites < ActiveRecord::Migration[8.0]
  def change
    add_column :invites, :telegram_username, :string
    add_index :invites, %i[telegram_username project_id], unique: true
  end
end

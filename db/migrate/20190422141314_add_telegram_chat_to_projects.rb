# frozen_string_literal: true

class AddTelegramChatToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :telegram_chat_id, :integer
  end
end

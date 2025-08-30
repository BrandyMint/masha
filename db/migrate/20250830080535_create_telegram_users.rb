# frozen_string_literal: true

class CreateTelegramUsers < ActiveRecord::Migration[8.0]
  def change
    create_table 'telegram_users', force: :cascade, id: :string do |t|
      t.string 'first_name'
      t.string 'last_name'
      t.string 'username'
      t.string 'photo_url'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
    end

    add_reference :users, :telegram_user
    remove_index :users, :telegram_user_id
    add_index :users, :telegram_user_id, unique: true
  end
end

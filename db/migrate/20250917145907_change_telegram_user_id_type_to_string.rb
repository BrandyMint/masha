class ChangeTelegramUserIdTypeToString < ActiveRecord::Migration[8.0]
  def change
    change_column :users, :telegram_user_id, :string
  end
end

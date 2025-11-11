class ChangeTelegramUsersIdToBigint < ActiveRecord::Migration[8.0]
  def up
    # Отключаем внешние ключи
    execute "ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_rails_8f176a9b49"

    # Конвертируем telegram_users.id в bigint
    add_column :telegram_users, :id_new, :bigint
    TelegramUser.reset_column_information
    TelegramUser.find_each do |user|
      user.update_column(:id_new, user.id.to_i)
    end
    remove_column :telegram_users, :id
    rename_column :telegram_users, :id_new, :id
    execute "ALTER TABLE telegram_users ADD PRIMARY KEY (id)"

    # Конвертируем users.telegram_user_id в bigint
    add_column :users, :telegram_user_id_new, :bigint
    User.reset_column_information
    User.where.not(telegram_user_id: nil).find_each do |user|
      user.update_column(:telegram_user_id_new, user.telegram_user_id.to_i)
    end
    remove_column :users, :telegram_user_id
    rename_column :users, :telegram_user_id_new, :telegram_user_id

    # Восстанавливаем внешний ключ с новыми типами данных
    execute "ALTER TABLE users ADD CONSTRAINT fk_rails_8f176a9b49 FOREIGN KEY (telegram_user_id) REFERENCES telegram_users(id)"
  end

  def down
    # Откатываем изменения
    execute "ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_rails_8f176a9b49"

    # Возвращаем telegram_users.id в string
    add_column :telegram_users, :id_old, :string
    TelegramUser.reset_column_information
    TelegramUser.find_each do |user|
      user.update_column(:id_old, user.id.to_s)
    end
    remove_column :telegram_users, :id
    rename_column :telegram_users, :id_old, :id
    execute "ALTER TABLE telegram_users ADD PRIMARY KEY (id)"

    # Возвращаем users.telegram_user_id в string
    add_column :users, :telegram_user_id_old, :string
    User.reset_column_information
    User.where.not(telegram_user_id_new: nil).find_each do |user|
      user.update_column(:telegram_user_id_old, user.telegram_user_id.to_s)
    end
    remove_column :users, :telegram_user_id
    rename_column :users, :telegram_user_id_old, :telegram_user_id

    # Восстанавливаем внешний ключ
    execute "ALTER TABLE users ADD CONSTRAINT fk_rails_8f176a9b49 FOREIGN KEY (telegram_user_id) REFERENCES telegram_users(id)"
  end
end

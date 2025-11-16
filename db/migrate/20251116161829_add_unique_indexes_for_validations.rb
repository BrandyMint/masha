# frozen_string_literal: true

class AddUniqueIndexesForValidations < ActiveRecord::Migration[8.0]
  def up
    # 1. Invite: заменяем индекс на email на составной индекс [email, project_id]
    # Сначала удаляем старый индекс
    remove_index :invites, name: 'index_invites_on_email', if_exists: true

    # Добавляем новый составной уникальный индекс
    # Это правильно отражает validates :email, uniqueness: { scope: [:project_id] }
    add_index :invites, %i[email project_id], unique: true, name: 'index_invites_on_email_and_project_id'

    # 2. Project.name - добавляем уникальный индекс
    add_index :projects, :name, unique: true, name: 'index_projects_on_name'

    # 3. User.nickname - добавляем уникальный индекс
    # allow_blank: true в валидации означает что NULL разрешен
    # PostgreSQL позволяет несколько NULL в unique индексе, что идеально
    add_index :users, :nickname, unique: true, name: 'index_users_on_nickname'

    # 4. User.pivotal_person_id - добавляем уникальный индекс
    add_index :users, :pivotal_person_id, unique: true, name: 'index_users_on_pivotal_person_id'
  end

  def down
    # Откатываем изменения в обратном порядке
    remove_index :users, name: 'index_users_on_pivotal_person_id', if_exists: true
    remove_index :users, name: 'index_users_on_nickname', if_exists: true
    remove_index :projects, name: 'index_projects_on_name', if_exists: true
    remove_index :invites, name: 'index_invites_on_email_and_project_id', if_exists: true

    # Восстанавливаем старый индекс на email
    add_index :invites, :email, unique: true, name: 'index_invites_on_email'
  end
end

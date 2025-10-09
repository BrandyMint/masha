# frozen_string_literal: true

# Роль пользователя в системе (не используется в текущей логике, зарезервирована для расширенных прав).
class Role < ApplicationRecord
  has_and_belongs_to_many :users, join_table: :users_roles
  belongs_to :resource, polymorphic: true

  # scopify
end

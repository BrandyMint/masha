# frozen_string_literal: true

class ClientAuthorizer < ApplicationAuthorizer
  def creatable_by?(user)
    # Любой пользователь может создавать компании
    true
  end

  def readable_by?(user)
    # Владелец компании + участники проектов компании + root пользователи могут просматривать
    owner?(user) || project_participant?(user) || user.is_root?
  end

  def updatable_by?(user)
    # Только владелец может редактировать
    owner?(user)
  end

  def deletable_by?(user)
    # Только владелец может удалять (с дополнительными проверками)
    owner?(user)
  end

  protected

  def owner?(user)
    resource.user_id == user.id
  end

  def project_participant?(user)
    # Проверяем, является ли пользователь участником любого проекта компании
    resource.projects.joins(:memberships)
                  .exists?(memberships: { user_id: user.id })
  end
end
# frozen_string_literal: true

class MembershipAuthorizer < ApplicationAuthorizer
  def creatable_by?(user)
    permission? user
  end

  def updatable_by?(user)
    return false if user.role?(:owner, resource.project) && user == resource.user

    permission? user
  end

  def deletable_by?(user)
    updatable_by? user
  end

  protected

  def permission?(user)
    user.is_root? || user.role?(:owner, resource.project)
  end
end

# frozen_string_literal: true

class ProjectAuthorizer < ApplicationAuthorizer
  def creatable_by?(user)
    has_permission? user
  end

  def updatable_by?(user)
    has_permission? user
  end

  def deletable_by?(user)
    updatable_by?(user) && resource.time_shifts.empty?
  end

  protected

  def has_permission?(user)
    user.is_root? || user.has_role?(:owner, resource)
  end
end

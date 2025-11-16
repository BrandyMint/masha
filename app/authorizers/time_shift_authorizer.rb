# frozen_string_literal: true

class TimeShiftAuthorizer < ApplicationAuthorizer
  def updatable_by?(user)
    permission?(user)
  end

  def deletable_by?(user)
    permission?(user)
  end

  protected

  def permission?(user)
    user.is_root? || user.role?(:owner, resource.project) || user.id == resource.user_id
  end
end

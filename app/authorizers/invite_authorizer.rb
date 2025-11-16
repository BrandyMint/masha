# frozen_string_literal: true

class InviteAuthorizer < ApplicationAuthorizer
  def deletable_by?(user)
    user.is_root? || user.role?(:owner, resource.project)
  end
end

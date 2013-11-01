class InviteAuthorizer < ApplicationAuthorizer
  def deletable_by? user
    user.is_root? || user.has_role?(:owner, resource.project)
  end
end

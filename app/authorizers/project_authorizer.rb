class ProjectAuthorizer < MembershipAuthorizer

	protected

	def has_permission?(user)
		user.is_root? || user.has_role?(:owner, resource)
	end

end
class Invite < ActiveRecord::Base

	include Authority::Abilities
	self.authorizer_name = 'InviteAuthorizer'

	belongs_to :user
	belongs_to :project

	scope :sent_by, -> (user) { where user: user }
	scope :sent_to, -> (user) { where email: user.email }

	validates :user, presence: true
	validates :email, presence: true, email: true, :uniqueness => { :scope => [:project_id] }
	validates :role, presence: true, :inclusion => { :in => Membership.roles.keys.map{|k| k.to_s} }
	validates :project, presence: true

	def self.activate_for(user)
		invites = self.sent_to(user)
		if invites.present?
			invites.each do |i|
				i.project.memberships.create(user: user, role: i.role)
			end
			invites.destroy_all
		end
	end

end

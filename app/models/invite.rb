class Invite < ActiveRecord::Base
  belongs_to :user
  belongs_to :project

  validates :user, presence: true
  validates :email, presence: true, :uniqueness => { :scope => [:project] }
  validates :role, presence: true, :inclusion => { :in => Membership.roles.keys.map{|k| k.to_s} }
  validates :project, presence: true

end

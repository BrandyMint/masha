class User < ActiveRecord::Base
  include Authority::UserAbilities

  has_many :time_shifts
  has_many :owned_projects, :class_name => 'Project', :foreign_key => :owner_id
  has_many :authentications
  has_many :memberships
  has_many :projects, :through => :memberships

  validates :name, :presence => true, :uniqueness => true
  validates :email, :email => true, :uniqueness => true, :allow_blank => true

  def to_s
    name
  end

  def by_provider prov
    authentications.by_provider(prov).first
  end

  def email
    # TODO change :develop to :email
    authentications.where(:provider=>:developer).pluck(:uid).first
  end

  def membership_of project
    memberships.where( :project_id=>project.id ).first
  end

  def has_role? role, project
    membership_of( project ).try( :role ) == role
  end

  def set_role role, project
    member = membership_of(project) || memberships.build(:project_id=>project.id)

    member.role = role
    member.save!
  end

end

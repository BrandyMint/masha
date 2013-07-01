class User < ActiveRecord::Base
  include Authority::UserAbilities
  include Authority::Abilities

  has_many :owned_projects, :class_name => 'Project', :foreign_key => :owner_id

  has_many :time_shifts
  has_many :timed_projects, :through => :time_shift, :class_name => 'Project'

  has_many :authentications, :dependent => :destroy
  has_many :memberships

  has_many :projects, :through => :memberships

  scope :ordered, -> { order :name }

  scope :reorder, lambda { |k| order :name }

  validates :name, :presence => true
  #validates :nickname, :uniqueness => true, :allow_blank => true
  validates :email, :email => true, :uniqueness => true, :allow_blank => true

  validates :pivotal_person_id, :uniqueness => true, :allow_blank => true, :numericality => true

  def to_s
    name
  end

  def available_users
  end

  def by_provider prov
    authentications.by_provider(prov).first
  end

  def email
    # TODO change :develop to :email
    authentications.where(:provider=>:developer).pluck(:uid).first || read_attribute(:email)
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

  def available_projects
    is_root? ? Project.ordered : projects.ordered
  end

end

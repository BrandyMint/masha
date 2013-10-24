class User < ActiveRecord::Base
  authenticates_with_sorcery!
  include Authority::UserAbilities
  include Authority::Abilities

  scope :ordered, -> { order :name }
  scope :reorder, lambda { |k| order :name }
  scope :without, -> (user) { where arel_table[:id].not_eq(user.id) }

  has_many :owned_projects, :class_name => 'Project', :foreign_key => :owner_id

  has_many :time_shifts
  has_many :timed_projects, :through => :time_shift, :class_name => 'Project'

  has_many :authentications, :dependent => :destroy
  has_many :memberships, :dependent => :destroy
  has_many :available_users, through: :memberships, uniq: true

  has_many :projects, :through => :memberships
  has_many :invites


  validates :name, :presence => true
  validates :nickname, :uniqueness => true, :allow_blank => true
  validates :pivotal_person_id, :uniqueness => true, :allow_blank => true, :numericality => true
  validates :email, :email => true, :uniqueness => true, :allow_blank => true

  # validates :password, :confirmation => true
  # validates :password, :presence => true, :on => :create

  # Пользователь репортер больше чем овнер?
  def reporter?
    # TODO настраивать в профиле
    memberships.members.count > memberships.count/2
  end

  def to_s
    name
  end

  def by_provider prov
    authentications.by_provider(prov).first
  end

  def email
    # TODO change :develop to :email
    authentications.where(:provider=>:developer).pluck(:uid).first || read_attribute(:email)
  end

  def membership_of project
    memberships.where( :project_id=>project.id ).first unless project.nil?
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
    projects.ordered
  end
end

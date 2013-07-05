class Membership < ActiveRecord::Base

  # TODO Можно ли этот список взять из enum?
  ROLES = [:owner, :viewer, :member]

  def self.roles_collection
    # TODO Перетащить человеческие названия в локаль, а список брать из ROLES
    {'владелец'=>:owner, 'смотритель'=>:viewer, 'участник'=>:member}
  end

  scope :last_updates, -> { order('updated_at desc') }
  scope :viewable, -> { order 'role_cd<2'}
  scope :owners,  -> { where :role_cd => 0 }
  scope :viewers, -> { where :role_cd => 1 }
  scope :members, -> { where :role_cd => 2 }

  belongs_to :user
  belongs_to :project

  as_enum :role, :owner => 0, :viewer => 1, :member => 2

  validates :user_id, :uniquenes => { :scope => :project_id }

end

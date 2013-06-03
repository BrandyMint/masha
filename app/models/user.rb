class User < ActiveRecord::Base
  rolify

  has_many :time_shifts
  has_many :owned_projects, :class_name => 'Project', :foreign_key => :owner_id
  has_many :authentications

  validates :name, :presence => true, :uniqueness => true
  validates :email, :email => true, :uniqueness => true, :allow_blank => true

  def to_s
    name
  end

  def email
    # TODO change :develop to :email
    authentications.where(:provider=>:developer).pluck(:uid).first
  end

  def available_projects
    owned_projects + Project.with_roles(:any, self).map(&:resource)
  end

end

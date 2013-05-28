class User < ActiveRecord::Base
  rolify

  has_many :time_shifts
  has_many :owner_projects, :foreign_key => :owner_id
  has_many :authentications

  def to_s
    name
  end

  def available_projects
    Project.with_roles(:any, self).map &:resource
  end

end

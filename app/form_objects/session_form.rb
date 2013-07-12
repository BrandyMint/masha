class SessionForm < FormObjectBase

  property :email
  property :password
  property :remember_me

  validates :email, presence: true, email: true
  validates :password, presence: true

end

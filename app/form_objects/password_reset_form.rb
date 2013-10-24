class PasswordResetForm < FormObjectBase

  property :email
  property :password
  property :password_confirmation

  validates :password, length: { minimum: 3 }
  validates :password, confirmation: true
  validates :password_confirmation, presence: true

  def user
    binding.pry
    user_params = to_hash
    @user ||= User.new(user_params)
  end

  def save
    user if valid? && user.save
  end

end

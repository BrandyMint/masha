class RegisterForm < FormObjectBase
  property :name
  property :email
  property :password

  validate :email_existence
  validates :name, presence: true
  validates :password, presence: true
  validates :email, presence: true, email: true

  def user
    user_params = to_hash
    @user ||= User.new(user_params)
  end

  def save
    user if valid? && user.save
  end

  private

  def email_existence
    errors.add(:email, I18n.t('errors.messages.taken')) if User.exists?(email: email)
  end
end

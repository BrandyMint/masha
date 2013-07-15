class RegisterForm < FormObjectBase

  property :name
  property :email
  property :password

  validates :name, presence: true
  validates :password, presence: true
  validates :email, presence: true, email: true
  before_validation :email_unique?

  def user
    user_params = to_hash
    @user ||= User.new(user_params)
  end

  def save
    valid? && user.save
  end

  private

  def email_unique?
    errors.add(:email, I18n.t('errors.messages.taken')) if User.exists?(email: self.email)
    errors.blank?
  end

end
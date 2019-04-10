class EmailForm < FormObjectBase
  property :email

  validates :email, presence: true, email: true
  validate :existing_email

  private

  def existing_email
    errors.add(:email, :no_user) unless User.find_by(email: email).present?
  end
end

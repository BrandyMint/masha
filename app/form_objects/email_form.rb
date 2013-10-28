class EmailForm < FormObjectBase
  property :email

  validates :email, presence: true
  validate :existing_email

  private

  def existing_email
    errors.add(:email, :no_user) unless User.find_by(email: self.email).present?
  end
end

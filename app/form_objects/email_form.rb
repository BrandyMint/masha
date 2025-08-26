# frozen_string_literal: true

class EmailForm < FormObjectBase
  property :email

  validates :email, presence: true, email: true
  validate :existing_email

  private

  def existing_email
    errors.add(:email, :no_user) if User.find_by(email: email).blank?
  end
end

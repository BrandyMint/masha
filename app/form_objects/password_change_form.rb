# frozen_string_literal: true

class PasswordChangeForm < FormObjectBase
  property :password
  property :password_confirmation

  validates :password, length: { minimum: 3 }
  validates :password, confirmation: true
  validates :password_confirmation, presence: true
end

class UserAuthorizer < ApplicationAuthorizer
  def readable_by?(user)
    user.available_users.include? resource
  end
end

class SessionForm < Hashie::Trash
  extend ActiveModel::Naming
  include ActiveModel::Validations

  property :email
  property :password

  def to_key
    nil
  end

  def persisted?
    false
  end
  
  def empty?
    keys.all? { |key| self[key].blank? }
  end
end

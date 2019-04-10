class FormObjectBase < Hashie::Trash
  include Hashie::Extensions::IndifferentAccess
  extend ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveRecord::Callbacks

  def to_key
    nil
  end

  def persisted?
    false
  end

  def empty?
    keys.all? { |key| self[key].blank? }
  end

  private

  def nilify_blanks(options = {})
    keys = options[:only] ||= self.keys
    keys.each do |key|
      self[key] = nil if self[key].blank?
    end
  end
end

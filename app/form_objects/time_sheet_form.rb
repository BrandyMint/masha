class TimeSheetForm < Hashie::Trash
  extend ActiveModel::Naming
  include ActiveModel::Validations

  GROUP_BY = [:project, :person]

  property :date_from
  property :date_to
  property :project_id
  property :user_id
  property :group_by

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

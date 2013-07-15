class TimeSheetForm < FormObjectBase

  GROUP_BY = [:project, :person]

  property :date_from
  property :date_to
  property :project_id
  property :user_id
  property :group_by

end

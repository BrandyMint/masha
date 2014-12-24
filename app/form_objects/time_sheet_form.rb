class TimeSheetForm < FormObjectBase
  GROUP_BY = [:project, :person]

  property :date_from
  property :date_to
  property :project_id
  property :user_id
  property :group_by

  def initialize(args)
    super args

    # Swap dates
    if date_to.present? && date_from.present? && Date.parse(date_to) < Date.parse(date_from)
      self.date_to, self.date_from = date_from, date_to
    end
  end
end

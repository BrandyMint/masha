class TimeSheetForm < FormObjectBase

  GROUP_BY = [:project, :person]

  property :date_from
  property :date_to
  property :project_id
  property :user_id
  property :group_by

  def initialize args
    super args

    # Swap dates
    if self.date_to.present? && self.date_from.present? && Date.parse(self.date_to)<Date.parse(self.date_from)
      self.date_to, self.date_from = self.date_from, self.date_to
    end
  end

end

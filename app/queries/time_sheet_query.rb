class TimeSheetQuery
  attr_accessor :time_sheet_form

  delegate :date_from, :date_, :to => :time_sheet_form

  def initialize collection, time_sheet_form
    @collection = collection
    @time_sheet_form = time_sheet_form
  end

  def perform

  end
end

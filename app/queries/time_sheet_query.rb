class TimeSheetQuery
  attr_accessor :tsf

  delegate *TimeSheetForm.properties.to_a, :to => :tsf

  def initialize collection, time_sheet_form
    @collection = collection
    @tsf = time_sheet_form
  end

  def perform
    scope = TimeShift.ordered

    scope = scope.where :project_id => project_id if project_id.present?
    scope = scope.where :user_id => user_id if user_id.present?
    scope = scope.where "date>=?", date_from if date_from.present?
    scope = scope.where "date<=?", date_to if date_to.present?

    if group_by.present?
      hash = {}

      scope.load.find_each do |ts|
        resource = group_resource_class.find ts.send( group_method )
        hash[resource.id] ||= {
          :resource => resource,
          :title => resource.to_s,
          :time_shifts => [],
          :total => 0,
          :min_date => nil,
          :max_date => nil }

        hr = hash[resource.id]

        hr[:time_shifts] << ts
        hr[:total] += ts.hours
        hr[:min_date] = ts.date if hr[:min_date].blank? || hr[:min_date]<ts.date
        hr[:max_date] = ts.date if hr[:max_date].blank? || hr[:max_date]>ts.date
      end

      hash.values
    else
      return [{ :title => 'Общее время',
                :time_shifts => scope,
                :total => scope.sum(:hours),
                :min_date => scope.minimum(:date),
                :max_date => scope.maximum(:date) }]
    end
  end

  private

  def group_method
    group_by == 'person' ? :user_id : :project_id
  end

  def group_resource_class
    group_by == 'person' ? User : Project
  end

end

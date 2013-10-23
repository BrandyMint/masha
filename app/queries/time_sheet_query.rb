class TimeSheetQuery
  attr_accessor :tsf, :result

  attr_accessor :available_projects, :available_users

  delegate *TimeSheetForm.properties.to_a, :to => :tsf

  def initialize  time_sheet_form
    @tsf = time_sheet_form
  end

  def perform
    scope = TimeShift.ordered.includes(:project, :user)

    scope = scope.where :project_id => project_id if project_id.present?
    scope = scope.where :project_id => available_projects_ids if available_projects.present?

    scope = scope.where :user_id => user_id if user_id.present?
    scope = scope.where :user_id => available_users_ids if available_users.present?

    scope = scope.where "date>=?", date_from if date_from.present?
    scope = scope.where "date<=?", date_to if date_to.present?

    if group_by.present?
      hash = {}

      scope.each do |ts|
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

      @result = hash.values
    else
      @result = [{ :title => 'Общее время',
                :time_shifts => scope,
                :total => scope.sum(:hours),
                :min_date => scope.minimum(:date),
                :max_date => scope.maximum(:date) }]
    end
  end

  def to_csv
    CSV.generate(col_sep: ';') do |csv|
      csv << ['date', 'hours', 'project', 'user', 'description']
      @result.each do |group|
        group[:time_shifts].each do |p|
          csv << [p.date, p.hours, p.project, p.user, p.description]
        end
      end
    end
  end

  private

  #def user_id
    #@uid ||= begin
               #uid = tsf.user_id
               #return nil unless uid

               #if available_users.present?
                 #available_user_ids.include?( uid ) ? uid : nil
               #else
                 #return uid
               #end
             #end
  #end

  #def project_id
    #@pid ||= begin
               #pid = tsf.project_id
               #return nil unless pid

               #if available_projects.present?
                 #available_project_ids.include?( pid ) ? pid : nil
               #else
                 #return pid
               #end
             #end
  #end

  def available_projects_ids
    available_projects.map &:id
  end

  def available_users_ids
    available_users.map &:id
  end

  def group_method
    group_by == 'person' ? :user_id : :project_id
  end

  def group_resource_class
    group_by == 'person' ? User : Project
  end

end

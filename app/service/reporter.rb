class Reporter

  def perform(user)
    query = SummaryQuery.for_user(user) period

    query.available_projects = projects
    query.available_users = users
    query.group_by = :project # :userparams[:group_by]
    query.perform

    binding.pry
  end

  private

  attr_reader :users, :period, :group_by, :projects
end

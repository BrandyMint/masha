module ApplicationHelper
  ROLES_LABELS = {
    :admin => 'important',
    :owner => 'warning',
    :viewer => 'info',
    :member => 'success'
  }

  def membership_roles_collection
    ['владелец'=>0, 'смотритель'=>1, 'участник'=>2]
  end

  def submit_sheet_button
    icon(:task)
  end

  def icon *classes
    css = classes.map{|c| "icon-#{c}"}.join(' ')
    content_tag :i, '', :class => "icon #{css}"
  end

  def badge count, css_id ='', type = ''
    # Скрываем badge если в нем пусто. JS сам его покажет когда появится информация
    #
    options = {
      :class => "badge badge-#{type}", :id => css_id
    }
    # options[:style] = 'visibility: hidden' if count.to_i == 0
    counter_tag count, options
  end

  def counter_tag count, options={}
    count = '' if count == 0
    content_tag :span, count, options
  end

  def grouping_collection
    [['none','']] + TimeSheetForm::GROUP_BY.map { |g| [g,g] }
  end

  def human_hours value
    str = Russian::pluralize value, 'час', 'часа', 'часов', 'часа'
    value = value.to_i if value.to_i == value
    "#{value} #{str}"
  end

  def title_of_group_results g
    dates = g[:min_date].present? ? ", с #{l g[:min_date]} по #{l g[:max_date]}" : ''
    "#{human_hours(g[:total])}#{dates}"
  end

  def setable_projects_collection
    @spc ||= available_projects
  end

  def viewable_projects_collection
    @vpc ||= available_projects
  end

  def available_users_to_set_collection
    users = []

    current_user.memberships.each do |m|
      if m.owner?
        users << m.project.users
      else
        users << m.user
      end
    end

    users.flatten.uniq
  end

  def available_users_to_view_collection
    #cache [:users_to_view, users_cache_key] do
      User.find( current_user.projects.map { |p| p.users.map &:id }.compact.uniq)
    #end
  end

  # TODO одни проекты ращрешены для ввода, другие для просмотра, не путать
  def available_projects
    current_user.projects.ordered
  end

  def user_roles user
    buffer = ''
    # TODO Показывтаь все роли на классы и глобальные
    buffer << role_label(:admin) if user.is_root?
    buffer.html_safe
  end

  def role_label role, active = true, title = nil
    return unless role.present?

    role = role.role if role.is_a? Membership

    label_class = active ? "label-#{ROLES_LABELS[role]}" : ''
    content_tag :span, (title || I18n.t(role, :scope => :roles)), :class => "label #{label_class}", :rel => :tooltip, :title => role
  end

  def user_roles_of_project user, project
    buffer = ''
    Project::ROLES.each do |role|
      buffer << role_label(role) if user.has_role? role, project
    end
    buffer.html_safe
  end

  def change_role_link user, project, role
    return # TODO
    active = user.has_role?(role, project)
    if active
      link_to remove_role_project_url(project, :user_id => user.id, :role => role), :method => :delete do
        role_label role, active
      end
    else
      link_to set_role_project_url(project, :user_id => user.id, :role => role), :method => :post do
        role_label role, active
      end
    end
  end

  private

  def users_cache_key
    key = current_user.memberships.order('updated_at desc').last.try(:updated_at)

    "#{current_user.id}-#{key}"
  end
end

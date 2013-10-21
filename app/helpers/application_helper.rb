module ApplicationHelper
  ROLES_LABELS = {
    :admin => 'important',
    :owner => 'warning',
    :viewer => 'info',
    :member => 'success'
  }

  def this_day_shifts
    current_user.time_shifts.ordered.this_day
  end

  def submit_sheet_button
    icon(:task)
  end

  def icon *classes
    css = classes.map{|c| "icon-#{c}"}.join(' ')
    content_tag :i, '', :class => "icon #{css}"
  end

  def check_email_existence
    if logged_in? && current_user.email.blank?
      flash[:alert] = t('no_email', url: edit_profile_path).html_safe
    end
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

  def human_date date
    str = I18n.l(date)
    wd = date.strftime '%a'
    str << " <span class='muted'>(#{wd})</span>"

    return str.html_safe
  end

  def grouping_collection
    [['none','']] + TimeSheetForm::GROUP_BY.map { |g| [g,g] }
  end

  def human_hours value
    return '-' if value.nil?
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
    #User.find( current_user.projects.map { |p| p.users.map &:id }.compact.uniq)
    @auvc = current_user.available_users.ordered

    if @auvc.exists? current_user
      user = OpenStruct.new(current_user.attributes.clone)
      user.name = user.name.clone.concat t('helpers.you')
      @auvc = @auvc.where("id <> ?", current_user.id).unshift user
    end

    @auvc
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
    Membership.roles.each_key do |role|
      buffer << role_label(role) if user.has_role? role, project
    end
    buffer.html_safe
  end

  def roles_select membership
    if current_user.can_update? membership
      render partial: 'memberships/roles', locals: {m: membership}
    else
      role_human membership.role
    end
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

  def role_human role
    I18n.t "roles.#{role.to_sym}"
  end

  private

  def users_cache_key
    key = current_user.memberships.order('updated_at desc').last.try(:updated_at)

    "#{current_user.id}-#{key}"
  end

  def supervisors_emails_of_project project
    project.memberships.supervisors.subscribers.map { |m| m.user.email }.compact
  end
end

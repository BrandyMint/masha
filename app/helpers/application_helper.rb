# frozen_string_literal: true

module ApplicationHelper
  def roles_collection
    @roles_collection ||= Membership.roles.keys.each_with_object([]) { |v, roles| roles << [t("roles.#{v}"), v] }
  end

  def summary_hours(summary, d, column)
    hsf = {
      date_from: d[:date],
      date_to: d[:date],
      group_by: :person
    }
    if summary[:group_by] == :project
      hsf[:project_id] = column.id
    else
      hsf[:user_id] = column.id
    end

    link_to time_shifts_url time_sheet_form: hsf do
      human_hours d[:columns][column.id]
    end
  end

  def summary_group_link(result)
    if result.group_by == :project
      link_to 'по проекту', summary_time_shifts_url(period: result[:period], group_by: :user),
              title: 'Переключить на сводку по исполнителям', role: :tooltip
    else
      link_to 'по исполнителю', summary_time_shifts_url(period: result[:period], group_by: :project),
              title: 'Переключить на сводку по проектам', role: :tooltip
    end
  end

  def summary_period_link(result)
    if result[:period] == :week
      link_to 'неделю', summary_time_shifts_url(period: :month), title: 'Переключить на сводку за месяц',
                                                                 role: 'tooltip'
    elsif result[:period] == :month
      link_to 'месяц', summary_time_shifts_url(period: :week), title: 'Переключить на сводку за неделю', role: 'tooltip'
    end
  end

  def week_day_class(date)
    # TODO: Расчитывать выходной согласно локали
    if date.cwday > 5
      'danger'
    elsif date.today?
      'active'
    else
      ''
    end
  end

  def app_version
    content_tag :small, class: 'text-muted', data: { version: AppVersion.to_s } do
      link_to "v#{AppVersion.format('%M.%m.%p')}", Settings.github_repo
    end
  end

  ROLES_LABELS = {
    admin: 'important',
    owner: 'warning',
    viewer: 'info',
    member: 'success'
  }.freeze

  def this_day_shifts
    current_user.time_shifts.ordered.this_day
  end

  def submit_sheet_button
    ficon(:tasks)
  end

  def icon(*classes)
    css = classes.map { |c| "icon-#{c}" }.join(' ')
    content_tag :i, '', class: "icon #{css}"
  end

  def badge(count, css_id = '', type = '')
    # Скрываем badge если в нем пусто. JS сам его покажет когда появится информация
    #
    options = {
      class: "badge badge-#{type}", id: css_id
    }
    # options[:style] = 'visibility: hidden' if count.to_i == 0
    counter_tag count, options
  end

  def counter_tag(count, options = {})
    count = '' if count.zero?
    content_tag :span, count, options
  end

  def human_date(date)
    I18n.l(date, format: :default_with_week_day).html_safe
  end

  def grouping_collection
    # [['none','']] + TimeSheetForm::GROUP_BY.map { |g| [g,g] }
    [[t('simple_form.labels.group.none'), '']] + TimeSheetForm::GROUP_BY.map do |g|
      [t("simple_form.labels.group.#{g}"), g]
    end
  end

  def human_hours(value)
    return '-' if value.nil?

    str = Russian.pluralize value, 'час', 'часа', 'часов', 'часа'
    value = value.to_i if value.to_i == value
    "#{value} #{str}"
  end

  def title_of_group_results(g)
    dates = g[:min_date].present? ? ", с #{l g[:min_date]} по #{l g[:max_date]}" : ''
    "#{human_hours(g[:total])}#{dates}"
  end

  def export_btn(format, options = {})
    link_to url_for({ format: format }.merge(options)), class: 'export-btn' do
      ficon('export-1') + t(format, scope: %i[helpers export])
    end
  end

  def setable_projects_collection
    @setable_projects_collection ||= available_projects
  end

  def viewable_projects_collection
    @viewable_projects_collection ||= available_projects
  end

  # def available_users_to_set_collection
  #   users = []
  #
  #   current_user.memberships.each do |m|
  #     if m.owner?
  #       users << m.project.users
  #     else
  #       users << m.user
  #     end
  #   end
  #
  #   users.flatten.uniq
  # end

  def available_users_to_view_collection
    # User.find( current_user.projects.map { |p| p.users.map &:id }.compact.uniq)
    #
    @auvc = current_user.active_available_users.without(current_user)

    user = OpenStruct.new(current_user.attributes.clone)
    user.name = user.name.clone.concat t('helpers.you')
    @auvc.unshift user

    @auvc
  end

  # TODO: одни проекты ращрешены для ввода, другие для просмотра, не путать
  def available_projects
    current_user.projects.active.ordered
  end

  def user_roles(user)
    buffer = ''
    # TODO: Показывтаь все роли на классы и глобальные
    buffer << role_label(:admin) if user.is_root?
    buffer.html_safe
  end

  def role_label(role, active = true, title = nil)
    return if role.blank?

    role = role.role if role.is_a? Membership

    label_class = active ? "label-#{ROLES_LABELS[role]}" : ''
    content_tag :span, (title || I18n.t(role, scope: :roles)), class: "label #{label_class}", rel: :tooltip, title: role
  end

  def user_roles_of_project(user, project)
    buffer = ''
    Membership.roles.each_key do |role|
      buffer << role_label(role) if user.has_role? role, project
    end
    buffer.html_safe
  end

  def roles_select(membership)
    if membership.project.active && current_user.can_update?(membership)
      render partial: 'memberships/roles', locals: { m: membership }
    else
      role_human membership.role
    end
  end

  def change_role_link(user, project, role)
    return # TODO
    active = user.has_role?(role, project)
    if active
      link_to remove_role_project_url(project, user_id: user.id, role: role), method: :delete do
        role_label role, active
      end
    else
      link_to set_role_project_url(project, user_id: user.id, role: role), method: :post do
        role_label role, active
      end
    end
  end

  def role_human(role)
    I18n.t "roles.#{role.to_sym}"
  end

  private

  def users_cache_key
    key = current_user.memberships.order('updated_at desc').last.try(:updated_at)

    "#{current_user.id}-#{key}"
  end

  def supervisors_emails_of_project(project)
    project.memberships.supervisors.subscribers.map { |m| m.user.email }.compact
  end

  def login_with_github(welcome = nil, _signup = nil)
    btn_class = welcome.present? ? 'btn-welcome-github' : 'btn-github'
    link_to "#{root_url}auth/github", class: btn_class.to_s do
      ficon('github-circled', size: 20,
                              v_align: :middle) + content_tag(:span, 'Войти через GitHub', style: 'margin-left: 8px')
    end
  end

  def set_change_password_title
    if current_user.crypted_password.present?
      t('titles.profile.change_password')
    else
      t('titles.profile.set_password')
    end
  end
end

# frozen_string_literal: true

# Helper методы для работы с fixtures и сложными тестовыми сценариями
# Используются для сценариев которые остаются в factories

module FixtureHelpers
  # Создает временную запись с произвольной датой
  # Используется для отчетов и тестов периодов
  def create_time_shift_with_date(user:, project:, date:, hours: 1.0, description: nil)
    description ||= "Test time shift for #{date}"
    TimeShift.create!(
      user: user,
      project: project,
      date: date,
      hours: hours,
      description: description
    )
  end

  # Создает несколько временных записей за период
  def create_time_shifts_for_period(user:, project:, start_date:, end_date:, hours_per_day: 1.0)
    time_shifts = []
    (start_date..end_date).each do |date|
      next if date.saturday? || date.sunday? # Пропускаем выходные

      time_shifts << create_time_shift_with_date(
        user: user,
        project: project,
        date: date,
        hours: hours_per_day
      )
    end
    time_shifts
  end

  # Устанавливает контекст для Telegram webhook тестов
  def setup_telegram_webhook_context(user)
    allow(controller).to receive(:current_user).and_return(user)
  end

  # Создает проект с клиентом
  def create_project_with_client(client_name:, project_name:, user:)
    client = Client.create!(
      key: client_name.parameterize.underscore,
      name: client_name,
      user: user
    )

    project = Project.create!(
      name: project_name,
      slug: project_name.parameterize.underscore,
      client: client,
      active: true,
      user: user
    )

    # Создаем membership для владельца
    Membership.create!(
      user: user,
      project: project,
      role: 'owner'
    )

    project
  end

  # Создает membership с произвольной ролью
  def create_membership_with_role(user:, project:, role:)
    Membership.create!(
      user: user,
      project: project,
      role: role
    )
  end

  # Создает пользователя с Telegram и заданным ID
  def create_user_with_telegram_id(telegram_id:, username: nil, user_attrs: {})
    telegram_user = TelegramUser.create!(
      id: telegram_id,
      username: username || "user_#{telegram_id}",
      first_name: 'Test',
      last_name: 'User'
    )

    user_attrs = {
      name: "User #{telegram_id}",
      nickname: "user_#{telegram_id}",
      email: "user#{telegram_id}@example.com",
      telegram_user_id: telegram_id,
      password_digest: BCrypt::Password.create('123')
    }.merge(user_attrs)

    User.create!(user_attrs)
  end

  # Создает сложную иерархию проектов для тестирования отчетов
  def create_project_hierarchy(user:, client_name:)
    client = create_project_with_client(
      client_name: client_name,
      project_name: "#{client_name} Main Project",
      user: user
    )

    # Создаем подпроекты
    sub_projects = []
    ['Development', 'Testing', 'Documentation'].each_with_index do |name, index|
      project = Project.create!(
        name: "#{client_name} #{name}",
        slug: "#{client_name.parameterize}_#{name.parameterize}",
        client: client,
        active: true
      )

      Membership.create!(
        user: user,
        project: project,
        role: 'owner'
      )

      sub_projects << project
    end

    {
      client: client,
      main_project: client.projects.first,
      sub_projects: sub_projects
    }
  end

  # Создает временные записи для отчета за период
  def create_time_shifts_for_report(user:, projects:, days_back: 7, hours_per_day: 2.0)
    time_shifts = []

    projects.each do |project|
      (1..days_back).each do |days_ago|
        date = days_ago.days.ago.to_date

        # Пропускаем выходные
        next if date.saturday? || date.sunday?

        # Добавляем случайные часы для реалистичности
        hours = hours_per_day + rand(-0.5..0.5).round(1)
        hours = [0.5, hours].max # Минимум 0.5 часа

        time_shifts << create_time_shift_with_date(
          user: user,
          project: project,
          date: date,
          hours: hours,
          description: "Работа над проектом #{project.name}"
        )
      end
    end

    time_shifts
  end

  # Создает пользователей с разными ролями в проекте
  def create_project_team(project:)
    team = {}

    # Владелец
    owner = create(:user, name: 'Project Owner')
    create_membership_with_role(user: owner, project: project, role: 'owner')
    team[:owner] = owner

    # Участники
    2.times do |i|
      member = create(:user, name: "Team Member #{i + 1}")
      create_membership_with_role(user: member, project: project, role: 'member')
      team[:members] ||= []
      team[:members] << member
    end

    # Наблюдатель
    watcher = create(:user, name: 'Project Watcher')
    create_membership_with_role(user: watcher, project: project, role: 'viewer')
    team[:watcher] = watcher

    team
  end

  # Создает контекст для callback query тестов
  def setup_callback_query_context(user, callback_data:)
    setup_telegram_webhook_context(user)

    @callback_query = {
      id: 'test_callback_id',
      from: {
        id: user.telegram_user&.id || 123456789,
        first_name: user.name.split.first,
        username: user.nickname
      },
      message: {
        message_id: 22,
        chat: { id: user.telegram_user&.id || 123456789 }
      },
      data: callback_data
    }
  end

  # Проверяет что пользователь имеет доступ к проекту
  def assert_user_can_access_project(user, project, expected_role = nil)
    membership = Membership.find_by(user: user, project: project)
    expect(membership).to be_present

    if expected_role
      expect(membership.role).to eq(expected_role.to_s)
    end
  end

  # Создает временные записи для разных пользователей
  def create_team_time_shifts(team:, project:, days_back: 5)
    time_shifts = []

    team.each do |role, users|
      Array(users).each do |user|
        (1..days_back).each do |days_ago|
          date = days_ago.days.ago.to_date
          next if date.saturday? || date.sunday?

          # Разные часы для разных ролей
          base_hours = case role
                      when :owner then 4
                      when :members then 6
                      when :watcher then 1
                      else 2
                      end

          hours = base_hours + rand(-1..1)
          hours = [0.5, hours].max

          time_shifts << create_time_shift_with_date(
            user: user,
            project: project,
            date: date,
            hours: hours,
            description: "#{role.to_s.capitalize} work"
          )
        end
      end
    end

    time_shifts
  end
end
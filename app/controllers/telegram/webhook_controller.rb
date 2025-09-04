# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Telegram
  class WebhookController < Telegram::Bot::UpdatesController
    Error = Class.new StandardError
    Unauthenticated = Class.new Error
    NotAvailableInPublicChat = Class.new Error

    include Telegram::Bot::UpdatesController::Session
    include Telegram::Bot::UpdatesController::MessageContext
    include Telegram::Bot::UpdatesController::CallbackQueryContext

    before_action :require_authenticated, only: %i[new! projects! add! adduser!]
    before_action :require_personal_chat, except: %i[attach! report! summary! add! projects! start! adduser!]

    rescue_from StandardError, with: :handle_error

    # This basic methods receives commonly used params:
    #
    #   message(payload)
    #   inline_query(query, offset)
    #   chosen_inline_result(result_id, query)
    #   callback_query(data)

    # Варианты ответов:
    #
    # Ответ в верхней шапке
    # answer_callback_query data
    #
    # Define public methods ending with `!` to handle commands.
    # Command arguments will be parsed and passed to the method.
    # Be sure to use splat args and default values to not get errors when
    # someone passed more or less arguments in the message.

    use_session!

    # use callbacks like in any other controllers
    around_action :with_locale

    # if message.left_chat_member && message.left_chat_member.username == ApplicationConfig.telegram_bot_name
    # bot.logger.info("Leave chat #{message.chat.title}")

    # elsif message.new_chat_members.any? && message.new_chat_members.map(&:username).include?(ApplicationConfig.telegram_bot_name)
    # bot.logger.info("Added to chat #{message.chat.title}")
    # bot.api.send_message(chat_id: message.chat.id,
    # text: "Привет всем!\nМеня зовут Маша.
    # Я помогаю учитывать ресурсы.\nПришлите /start@#{ApplicationConfig.telegram_bot_name} чтобы познакомиться лично.")

    # Every update can have one of: message, inline_query, chosen_inline_result,
    # callback_query, etc.
    # Define method with same name to respond to this updates.
    def message(_message)
      # message can be also accessed via instance method
      payload # true
      # store_message(message['tex'])
      respond_with :message, text: 'Я не Алиса, мне нужна конкретика. Жми /help'
    end

    def chosen_inline_result(_result_id, _query)
      respond_with :message, text: 'Неизвестный тип сообщение chosen_inline_result'
    end

    def inline_query(_query, _offset)
      respond_with :message, text: 'Неизвестный тип сообщение inline_query'
    end

    def callback_query(data)
      edit_message :text, text: "Вы выбрали #{data}"
    end

    def select_project_callback_query(project_slug)
      save_context :add_time
      project = find_project project_slug
      session[:add_time_project_id] = project.id
      edit_message :text,
                   text: "Вы выбрали проект #{project.slug}, теперь укажите время и через пробел комментарий (12 делал то-то)"
    end

    def adduser_project_callback_query(project_slug)
      project = find_project(project_slug)
      unless project
        edit_message :text, text: 'Проект не найден'
        return
      end

      # Check permissions - only owners can add users
      membership = current_user.membership_of(project)
      unless membership&.owner?
        edit_message :text, text: 'У вас нет прав для добавления пользователей в этот проект, только владелец (owner) может это сделать.'
        return
      end

      session[:adduser_project_slug] = project_slug
      save_context :adduser_username_input
      edit_message :text, text: "Проект: #{project.name}\nТеперь введите никнейм пользователя (например: @username или username):"
    end

    def adduser_username_input(username, *)
      username = username.delete_prefix('@') if username.start_with?('@')
      session[:adduser_username] = username

      save_context :adduser_role_callback_query
      respond_with :message,
                   text: "Пользователь: @#{username}\nВыберите роль для пользователя:",
                   reply_markup: {
                     inline_keyboard: [
                       [{ text: 'Владелец (owner)', callback_data: 'adduser_role:owner' }],
                       [{ text: 'Наблюдатель (viewer)', callback_data: 'adduser_role:viewer' }],
                       [{ text: 'Участник (member)', callback_data: 'adduser_role:member' }]
                     ]
                   }
    end

    def adduser_role_callback_query(role)
      project_slug = session[:adduser_project_slug]
      username = session[:adduser_username]

      # Clean up session
      session.delete(:adduser_project_slug)
      session.delete(:adduser_username)

      edit_message :text, text: "Добавляем пользователя @#{username} в проект #{project_slug} с ролью #{role}..."

      add_user_to_project(project_slug, username, role)
    end

    def add_time(hours, *description)
      project = current_user.available_projects.find(session[:add_time_project_id]) || raise('Не указан проект')
      description = description.join(' ')
      project.time_shifts.create!(
        date: Time.zone.today,
        hours: hours.to_s.tr(',', '.').to_f,
        description: description,
        user: current_user
      )

      respond_with :message, text: "Отметили в #{project.name} #{hours} часов"
    end

    def summary!(period = 'week', *)
      text = Reporter.new.projects_to_users_matrix(current_user, period.to_sym)
      respond_with :message, text: code(text), parse_mode: :Markdown
    end

    def report!(*)
      text = Reporter.new.list_by_days(current_user, group_by: :user)
      text << "\n"
      text << Reporter.new.list_by_days(current_user, group_by: :project)

      respond_with :message, text: code(text), parse_mode: :Markdown
    end

    def projects!(_data = nil, *)
      text = multiline 'Доступные проекты:', nil, current_user.available_projects.alive.join(', ')
      respond_with :message, text: text
    end

    def attach!(project_slug = nil, *)
      if project_slug.blank?
        message = 'Укажите первым аргументом проект, к которому присоединяете этот чат'
      elsif chat['id'].to_i.negative?
        project = find_project(project_slug)
        project.update telegram_chat_id: chat['id']
        message = "Установили этот чат основным в проекте #{project}"
      else
        message = 'Присоединять можно только чаты, личную переписку нельзя'
      end
      respond_with :message, text: message
    end

    def start!(word = nil, *_other_words)
      if word.to_s.start_with? TelegramHelper::AUTH_PREFIX
        session_token = word.delete TelegramHelper::AUTH_PREFIX
        verifier = Rails.application.message_verifier :telegram
        data = { st: session_token, tid: telegram_user.id, t: Time.zone.now.to_i }
        token = verifier.generate(data, purpose: :login)
        respond_with :message,
                     text: "Вы авторизованы! Перейдите на сайт: #{Rails.application.routes.url_helpers.telegram_confirm_url(token:)}"
      elsif logged_in?
        respond_with :message, text: multiline('С возращением!', nil, nil, help_message)
      else
        respond_with :message,
                     text: "Привет! Чтобы авторизоваться перейдите на сайт: #{Rails.application.routes.url_helpers.new_session_url}"
      end
    end

    def help!(*)
      respond_with :message, text: help_message
    end

    def version!(*)
      respond_with :message, text: "Версия Маши: #{AppVersion}"
    end

    def add!(project_slug = nil, hours = nil, *description)
      if project_slug.nil?
        save_context :add_callback_query
        respond_with :message,
                     text: 'Выберите проект, в котором отметить время:',
                     reply_markup: {
                       resize_keyboard: true,
                       inline_keyboard:
                       current_user.available_projects.alive
                                   .map { |p| { text: p.name, callback_data: "select_project:#{p.slug}" } }
                                   .each_slice(3).to_a
                     }
        return
      end

      project = find_project(project_slug)
      description = description.join(' ')

      if project.present?
        project.time_shifts.create!(
          date: Time.zone.today,
          hours: hours.to_s.tr(',', '.').to_f,
          description: description,
          user: current_user
        )

        message = "Отметили в #{project.name} #{hours} часов"
      else
        message = "Не найден такой проект '#{project_slug}'. Вам доступны: #{current_user.available_projects.alive.join(', ')}"
      end

      respond_with :message, text: message
    end

    def new!(slug = nil, *)
      project = current_user.projects.create!(name: slug, slug: slug)

      respond_with :message, text: "Создан проект `#{project.slug}`"
    end

    def adduser!(project_slug = nil, username = nil, role = 'member', *)
      if project_slug.blank?
        # Interactive mode - show project selection (only projects where user is owner)
        manageable_projects = current_user.available_projects.alive.joins(:memberships)
                                          .where(memberships: { user: current_user, role_cd: 0 })

        if manageable_projects.empty?
          respond_with :message, text: 'У вас нет проектов, в которые можно добавить пользователей'
          return
        end

        save_context :adduser_project_callback_query
        respond_with :message,
                     text: 'Выберите проект, в который хотите добавить пользователя:',
                     reply_markup: {
                       inline_keyboard: manageable_projects.map { |p| [{ text: p.name, callback_data: "adduser_project:#{p.slug}" }] }
                     }
        return
      end

      if username.blank?
        respond_with :message, text: 'Укажите никнейм пользователя (например: @username или username)'
        return
      end

      add_user_to_project(project_slug, username, role)
    end

    private

    def add_user_to_project(project_slug, username, role)
      # Remove @ from username if present
      username = username.delete_prefix('@')

      project = find_project(project_slug)
      unless project
        respond_with :message, text: "Не найден проект '#{project_slug}'. Вам доступны: #{current_user.available_projects.alive.join(', ')}"
        return
      end

      # Check if current user can manage this project (owner or viewer role)
      membership = current_user.membership_of(project)
      unless membership&.owner?
        respond_with :message, text: "У вас нет прав для добавления пользователей в проект '#{project.slug}', " \
                                     'только владелец (owner) может это сделать.'
        return
      end

      # Find user by Telegram username
      telegram_user = TelegramUser.find_by(username: username)
      unless telegram_user
        respond_with :message, text: "Пользователь с никнеймом '@#{username}' не найден. " \
                                     'Пользователь должен сначала авторизоваться через бота.'
        return
      end

      user = telegram_user.user
      unless user
        respond_with :message, text: "Пользователь '@#{username}' не привязан к системе. Попросите его авторизоваться через /start"
        return
      end

      # Check if user is already in project
      existing_membership = user.membership_of(project)
      if existing_membership
        respond_with :message, text: "Пользователь '@#{username}' уже участвует в проекте '#{project.slug}' " \
                                     "с ролью #{existing_membership.role}"
        return
      end

      # Validate role
      role = role.downcase
      unless Membership.roles.keys.include?(role)
        respond_with :message, text: "Неверная роль '#{role}'. Доступные роли: #{valid_roles.join(', ')}"
        return
      end

      # Add user to project
      user.set_role(role.to_sym, project)

      respond_with :message, text: "Пользователь '@#{username}' добавлен в проект '#{project.slug}' с ролью '#{role}'"
    end

    def help_message
      multiline(
        '/help - Эта подсказка',
        '/version - Версия Маши',
        '/projects - Список проектов',
        '/attach {projects_slug} - Указать проект этого чата',
        '/add {project_slug} {hours} {comment} - Отметить время',
        '/new {project_slug} - Создать новый проект',
        '/adduser {project_slug} {username} [role] - Добавить пользователя в проект (роли: owner, viewer, member)',
        '/report - Детальный отчёт по командам и проектам',
        '/summary {week|month}- Сумарный отчёт за период'
      )
    end

    def multiline(*args)
      args.flatten.map(&:to_s).join("\n")
    end

    def generate_start_link
      TelegramVerifier.get_link(
        uid: from['id'],
        nickname: from['username'],
        name: [from['first_name'], from['last_name']].compact.join(' ')
      )
    end

    def with_locale(&block)
      I18n.with_locale(current_locale, &block)
    end

    def current_user
      return unless from
      return @current_user if defined? @current_user

      @current_user = User.joins(:authentications).find_by(authentications: { provider: :telegram, uid: from['id'] })
    end

    def require_authenticated
      raise Unauthenticated unless logged_in?
    end

    def require_personal_chat
      raise NotAvailableInPublicChat unless is_personal_chat?
    end

    def logged_in?
      current_user.present?
    end

    def current_locale
      if from
        # locale for user
        :ru
      elsif chat
        # locale for chat
        :ru
      end
    end

    def code(text)
      multiline '```', text, '```'
    end

    def is_personal_chat?
      chat['id'] == from['id']
    end

    def find_project(key)
      current_user.available_projects.alive.find_by(slug: key)
    end

    def logger
      Rails.application.config.telegram_updates_controller.logger
    end

    # In this case session will persist for user only in specific chat.
    # Same user in other chat will have different session.
    def session_key
      "#{bot.username}:#{chat['id']}:#{from['id']}" if chat && from
    end

    def attached_project
      current_user.available_projects.find_by(telegram_chat_id: chat['id'])
    end

    def handle_error(error)
      case error
      when Telegram::Bot::Forbidden
        Rails.logger.error error
      when NotAvailableInPublicChat
        # do nothing
      when Unauthenticated
        respond_with :message, text: multiline(
          "Привет, #{from['first_name']}!",
          nil,
          "Привяжи телеграм к своему аккаунту по этой ссылке: #{generate_start_link}"
        )
      else # ActiveRecord::ActiveRecordError
        Rails.logger.error error
        Bugsnag.notify error do |b|
          b.meta_data = { chat: chat, from: from }
        end
        respond_with :message, text: "Error: #{error.message}"
      end
    end

    # Пользователь написал в бота и заблокировал его (наверное добавлен где-то в канале или тп)
    def bot_forbidden(error)
      Bugsnag.notify error
      Rails.logger.error "#{error} #{chat.to_json}"
    end

    # У бота уже нет доступа отвечать в чат
    #
    def bot_error(error)
      Bugsnag.notify error
      Rails.logger.error "#{error} #{chat.to_json}"
    end

    def current_bot_id
      bot.token.split(':').first
    end

    def telegram_user
      @telegram_user ||= TelegramUser
                         .create_with(chat.slice(*%w[first_name last_name username]))
                         .create_or_find_by! id: chat.fetch('id')
    end

    def notify_bugsnag(message)
      Rails.logger.err message
      Bugsnag.notify message do |b|
        b.metadata = payload
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength

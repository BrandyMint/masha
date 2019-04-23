class Telegram::WebhookController < Telegram::Bot::UpdatesController
  Error = Class.new StandardError
  Unauthenticated = Class.new Error
  NotAvailableInPublicChat = Class.new Error

  include Telegram::Bot::UpdatesController::Session
  include Telegram::Bot::UpdatesController::MessageContext

  before_action :require_personal_chat, except: [:report!, :summary!, :add!, :projects!, :start!]
  before_action :require_authenticated, only: [:projects!, :add!, :start!]

  rescue_from StandardError, with: :handle_error

  # This basic methods receives commonly used params:
  #
  #   message(payload)
  #   inline_query(query, offset)
  #   chosen_inline_result(result_id, query)
  #   callback_query(data)

  # Define public methods ending with `!` to handle commands.
  # Command arguments will be parsed and passed to the method.
  # Be sure to use splat args and default values to not get errors when
  # someone passed more or less arguments in the message.

  use_session!

  # use callbacks like in any other controllers
  around_action :with_locale

  #if message.left_chat_member && message.left_chat_member.username == Settings.telegram_bot_name
    #bot.logger.info("Leave chat #{message.chat.title}")

  #elsif message.new_chat_members.any? && message.new_chat_members.map(&:username).include?(Settings.telegram_bot_name)
    #bot.logger.info("Added to chat #{message.chat.title}")
    #bot.api.send_message(chat_id: message.chat.id, text: "Привет всем!\nМеня зовут Маша. Я помогаю учитывать ресурсы.\nПришлите /start@#{Settings.telegram_bot_name} чтобы познакомиться лично.")

  # Every update can have one of: message, inline_query, chosen_inline_result,
  # callback_query, etc.
  # Define method with same name to respond to this updates.
  def message(message)
    # message can be also accessed via instance method
    message == self.payload # true
    # store_message(message['text'])
    respond_with :message, text: 'Я не Алиса, мне нужна конкретика. Жми /help'
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

  def projects!(data = nil, *)
    text = multiline 'Доступные проекты:', nil, current_user.available_projects.join(', ')
    respond_with :message, text: text
  end

  def attach!(project_slug = nil, *)
    if project_slug.blank?
      message = 'Укажите первым аргументом проект, к которому присоединяете этот чат'
    elsif chat['id'].to_i < 0
      project = find_project(project_slug)
      project.update telegram_chat_id: chat[:id]
      message = "Установили этот чат основным в проекте #{project}"
    else
      message = 'Присоединять можно только чаты, личную переписку нельзя'
    end
    respond_with :message, text: message
  end

  def start!(data = nil, *)
    respond_with :message, text: multiline( 'Мы уже знакомы.', nil, nil, help_message )
  end

  def help!(*)
    respond_with :message, text: help_message
  end

  def add!(project_slug = nil, hours = nil, *description)
    description = description.join(' ')

    project = find_project(project_slug)

    if project.present?
      project.time_shifts.create!(
        date: Date.today,
        hours: hours.to_s.tr(',','.').to_f,
        description: description,
        user: current_user
      )

      message = "Отметили в #{project.name} #{hours} часов"
    else
      message = "Не найден такой проект '#{project_slug}'. Вам доступны: #{ current_user.available_projects.join(', ') }"
    end

    respond_with :message, text: message
  end

  def new!(slug = nil, *)
    project = current_user.projects.create!(name: slug, slug: slug)

    respond_with :message, text: "Создан проект `#{project.slug}`"
  end

  private

  def help_message
    multiline(
      '/help - Эта подсказка',
      '/projects - Список проектов',
      '/add {project_slug} {hours} {comment} - Отметить время',
      '/new {project_slug} - Создать новый проект',
      '/report - Детальный по команды и проектам',
      '/summary {week|summary}- Сумарное за период',
      '/attach {project_slug} - Присоеденить текущий чат к проекту'
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
    @current_user = User.joins(:authentications).find_by(authentications: { provider: :telegram, uid: from['id']})
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
    current_user.available_projects.active.find_by_slug(key)
  end

  def logger
    Rails.application.config.telegram_updates_controller.logger
  end

  # In this case session will persist for user only in specific chat.
  # Same user in other chat will have different session.
  def session_key
    "#{bot.username}:#{chat['id']}:#{from['id']}" if chat && from
  end

  def handle_error(error)
    case error
    when Telegram::Bot::Forbidden
      logger.error(error)
    when NotAvailableInPublicChat
      # do nothing
    when Unauthenticated
      respond_with :message, text: multiline(
        "Привет, #{from['first_name']}!",
        nil,
        "Привяжи телеграм к своему аккаунту по этой ссылке: #{generate_start_link}"
      )
    else # ActiveRecord::ActiveRecordError
      logger.error error
      Bugsnag.notify error do |b|
        b.meta_data = { chat: chat, from: from }
      end
      respond_with :message, text: "Error: #{err.message}"
    end
  end
end

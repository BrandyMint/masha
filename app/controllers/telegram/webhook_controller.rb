class Telegram::WebhookController < Telegram::Bot::UpdatesController
  Error = Class.new StandardError
  Unauthenticated = Class.new Error
  NotAvailableInPublicChat = Class.new Error

  include Telegram::Bot::UpdatesController::Session
  include Telegram::Bot::UpdatesController::MessageContext

  before_action :require_personal_chat, except: [:report!, :add!, :projects!, :start!]
  before_action :require_authenticated, only: [:projects!, :add!, :start!]
  rescue_from Telegram::Bot::Forbidden, with: -> (error) { logger.error error }
  rescue_from NotAvailableInPublicChat, with: -> { } # do nothing
  rescue_from Unauthenticated, with: :handle_unauthenticated

  # rescue_from ArgumentError, with: -> { respond_with :message, text: 'Rescued' }
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

  def report!(project_slug = nil, *)
    text = Reporter.new.perform(current_user, group_by: :user)
    text << "\n"
    text << Reporter.new.perform(current_user, group_by: :project)

    respond_with :message, text: "```#{text}```", parse_mode: :Markdown
  end

  def projects!(data = nil, *)
    text = multiline 'Доступные проекты:', nil, current_user.available_projects.join(', ')
    respond_with :message, text: text
  end

  def start!(data = nil, *)
    respond_with :message, text: multiline( 'Мы уже знакомы.', nil, nil, help_message )
  end

  def help!(*)
    respond_with :message, text: help_message
  end

  def add!(project_id = nil, hours = nil, *description)
    description = description.join(' ')

    project = find_project(project_id)

    if project.present?
      project.time_shifts.create!(
        date: Date.today,
        hours: hours.to_s.tr(',','.').to_f,
        description: description,
        user: current_user
      )

      message = "Отметили в #{project.name} #{hours} часов"
    else
      message = "Не найден такой проект '#{project_id}'. Вам доступны: #{ current_user.available_projects.join(', ') }"
    end

    respond_with :message, text: message
  rescue => err
    respond_with :message, text: "Error: #{err.message}"
  end

  private

  def help_message
    multiline(
      '/help - эта подсказка',
      '/projects - список проектов',
      '/add {project_id} {hours} {comment} - отметить время'
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

  def handle_unauthenticated
    message = multiline(
      "Привет, #{from['first_name']}!",
      nil,
      "Привяжи телеграм к своему аккаунту по этой ссылке: #{generate_start_link}"
    )

    respond_with :message, text: message
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
end

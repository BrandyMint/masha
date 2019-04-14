class Telegram::WebhookController < Telegram::Bot::UpdatesController
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

  def projects!(data = nil, *)
    if logged_in?
      text = multiline 'Доступные проекты:', nil, current_user.projects.join(', ')
    else
      text = "Сначала привяжите аккаунт (/start)"
    end

    respond_with :message, text: text
  end

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
  def start!(data = nil, *)
    if logged_in?
      respond_with :message, text: multiline( 'Мы уже знакомы.', nil, nil, help_message )
    else
      response = multiline(
        "Привет, #{from[:first_name]}!",
        nil,
        "Привяжи телеграм к своему аккаунту по этой ссылке: #{generate_start_link}"
      )

      # response = from ? "Hello #{from['username']}!" : 'Hi there!'
      respond_with :message, text: response
    end

    # `reply_with` also sets `reply_to_message_id`:
    # reply_with :photo, photo: File.open('party.jpg')
  end

  def help!(*)
    respond_with :message, text: help_message
  end

  def add!(project_id = nil, time = nil, *comment)
    comment = comment.join(' ')
    respond_with :message, text: "Эта команда еще не готова, но вы прислали project_id=#{project_id}, time=#{time}, comment=#{comment}"
  end

  private

  def help_message
    multiline(
      '/help - эта подсказка',
      '/projects - список проектов',
      '/add {project_id} {time} {comment} - отметить время'
    )
  end

  def multiline(*args)
    args.flatten.map(&:to_s).join("\n")
  end

  def generate_start_link
    TelegramVerifier.get_link(
      uid: from[:id],
      nickname: from[:username],
      name: [from[:first_name], from[:last_name]].compact.join(' ')
    )
  end

  def with_locale(&block)
    I18n.with_locale(current_locale, &block)
  end

  def current_user
    return unless from
    return @current_user if defined? @current_user
    @current_user = User.joins(:authentications).find_by(authentications: { provider: :telegram, uid: from[:id]})
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
end

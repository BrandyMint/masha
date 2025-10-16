# frozen_string_literal: true

module Telegram
  class WebhookController < Telegram::Bot::UpdatesController
    Error = Class.new StandardError
    Unauthenticated = Class.new Error
    NotAvailableInPublicChat = Class.new Error

    include Telegram::Bot::UpdatesController::Session
    include Telegram::Bot::UpdatesController::MessageContext
    include Telegram::Bot::UpdatesController::CallbackQueryContext
    include TelegramCallbacks
    include TelegramHelpers
    include TelegramSessionHelpers

    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :require_authenticated, only: %i[new! projects! add! adduser! hours! edit! rename!]
    before_action :require_personal_chat, except: %i[attach! report! summary! add! projects! start! adduser! rename!]
    # rubocop:enable Rails/LexicallyScopedActionFilter

    rescue_from StandardError, with: :handle_error

    use_session!

    # use callbacks like in any other controllers
    around_action :with_locale

    # Dynamic command method definitions
    %w[summary report projects attach start help version users merge add new adduser hours edit rename set_commands].each do |command|
      define_method "#{command}!" do |*args|
        command_class = "Telegram::Commands::#{command.camelize}Command".constantize
        command_class.new(self).call(*args)
      end
    end

    # Core message handlers
    def message(message)
      text = if message.is_a?(String)
               message.strip
             else
               message['text']&.strip
             end

      # If user is not logged in, show default message
      return respond_with(:message, text: 'Я не Алиса, мне нужна конкретика. Жми /help') unless logged_in?

      return respond_with(:message, text: 'Я не Алиса, мне нужна конкретика. Жми /help') if text.blank?

      # Try to parse time tracking message in format: {hours} {project_slug} [description] or {project_slug} {hours} [description]
      parts = text.split(/\s+/)
      return respond_with(:message, text: 'Я не Алиса, мне нужна конкретика. Жми /help') if parts.length < 2

      tracker = TelegramTimeTracker.new(current_user, parts, self)
      result = tracker.parse_and_add

      if result[:error]
        respond_with :message, text: result[:error]
      elsif result[:success]
        # Success message is handled by the tracker
      else
        respond_with :message, text: 'Я не Алиса, мне нужна конкретика. Жми /help'
      end
    end

    def chosen_inline_result(_result_id, _query)
      respond_with :message, text: 'Неизвестный тип сообщение chosen_inline_result'
    end

    def inline_query(_query, _offset)
      respond_with :message, text: 'Неизвестный тип сообщение inline_query'
    end

    private

    def merge_telegram_user_with_email_user(email_user, telegram_only_user, telegram_user)
      Rails.logger.info "Starting merge of telegram_only_user #{telegram_only_user.id} into email_user #{email_user.id}"

      # Проверки перед слиянием
      raise "Telegram user #{telegram_only_user.id} has email, cannot merge" if telegram_only_user.email.present?
      raise "Email user #{email_user.id} has no email, cannot merge" if email_user.email.blank?
      raise "Email user #{email_user.id} already has telegram_user_id, cannot merge" if email_user.telegram_user_id.present?

      User.transaction do
        # 1. Перенос authentications
        telegram_only_user.authentications.each do |auth|
          # Проверяем на конфликты
          existing_auth = email_user.authentications.find_by(provider: auth.provider, uid: auth.uid)
          if existing_auth
            Rails.logger.info "Skipping duplicate authentication #{auth.provider}:#{auth.uid}"
            auth.destroy!
          else
            auth.update!(user: email_user)
          end
        end

        # 2. Перенос memberships с обработкой дублей
        telegram_only_user.memberships.each do |membership|
          existing_membership = email_user.memberships.find_by(project: membership.project)
          if existing_membership
            # Выбираем более высокую роль (owner > viewer > member)
            role_priority = { 'owner' => 3, 'viewer' => 2, 'member' => 1 }
            current_priority = role_priority[existing_membership.role] || 0
            new_priority = role_priority[membership.role] || 0

            if new_priority > current_priority
              existing_membership.update!(role: membership.role)
              Rails.logger.info "Updated role for project #{membership.project.slug} to #{membership.role}"
            end
            membership.destroy!
          else
            membership.update!(user: email_user)
          end
        end

        # 3. Перенос time_shifts
        # rubocop:disable Rails/SkipsModelValidations
        telegram_only_user.time_shifts.update_all(user_id: email_user.id)

        # 4. Перенос invites
        # Отправленные приглашения
        telegram_only_user.invites.update_all(user_id: email_user.id)

        # Полученные приглашения по email (если у telegram_only_user был email)
        if telegram_only_user.read_attribute(:email).present?
          Invite.where(email: telegram_only_user.read_attribute(:email))
                .update_all(email: email_user.email)
        end
        # rubocop:enable Rails/SkipsModelValidations

        # Удаляем старого пользователя
        telegram_only_user.destroy!

        # 5. Финализация слияния
        # Привязываем telegram_user к email_user
        email_user.update!(telegram_user: telegram_user)

        Rails.logger.info "Successfully merged telegram_only_user #{telegram_only_user.id} into email_user #{email_user.id}"
      end

      # Отправляем уведомление
      TelegramNotificationJob.perform_later(
        user_id: telegram_user.id,
        message: "🎉 Ваш Telegram аккаунт был объединен с веб-аккаунтом #{email_user.email}!"
      )
    rescue StandardError => e
      Rails.logger.error "Error merging accounts: #{e.message}"
      Bugsnag.notify e do |b|
        b.meta_data = {
          email_user_id: email_user.id,
          telegram_only_user_id: telegram_only_user.id,
          telegram_user_id: telegram_user.id
        }
      end
      raise e
    end

    def with_locale(&block)
      I18n.with_locale(current_locale, &block)
    end

    def require_authenticated
      raise Unauthenticated unless logged_in?
    end

    def require_personal_chat
      raise NotAvailableInPublicChat unless is_personal_chat?
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
  end
end

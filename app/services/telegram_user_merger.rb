# frozen_string_literal: true

class TelegramUserMerger
  def initialize(email, telegram_username, controller:)
    @email = email
    @telegram_username = telegram_username.delete_prefix('@')
    @controller = controller
  end

  def merge
    # Find user by email
    user = User.find_by(email: @email)
    unless user
      respond_with_error("Пользователь с email '#{@email}' не найден")
      return
    end

    # Check if user already has telegram_user_id
    if user.telegram_user_id.present?
      telegram_user = user.telegram_user
      respond_with_error("Пользователь с email '#{@email}' уже привязан к Telegram аккаунту " \
                         "@#{telegram_user.username} (#{telegram_user.name})")
      return
    end

    # Find telegram user by username
    telegram_user = TelegramUser.find_by(username: @telegram_username)
    unless telegram_user
      respond_with_error("Telegram пользователь '@#{@telegram_username}' не найден в системе")
      return
    end

    # Check if telegram user is already linked to another user
    if telegram_user.user.present?
      existing_user = telegram_user.user

      # If existing user has no email, we can merge it with the email user
      if existing_user.email.blank?
        begin
          merge_telegram_user_with_email_user(user, existing_user, telegram_user)
          respond_with_success("✅ Успешно объединили аккаунты:\n📧 Email: #{@email}\n📱 Telegram: @#{@telegram_username}")
          return
        rescue StandardError => e
          respond_with_error("❌ Ошибка при объединении аккаунтов: #{e.message}")
          return
        end
      else
        # Existing user has email, cannot merge
        respond_with_error("Telegram аккаунт '@#{@telegram_username}' уже привязан к пользователю #{existing_user.email}")
        return
      end
    end

    # Perform the merge
    user.update!(telegram_user: telegram_user)

    # Send notification to the user via Telegram
    TelegramNotificationJob.perform_later(
      user_id: telegram_user.id,
      message: "🎉 Ваш Telegram аккаунт был объединен с веб-аккаунтом #{@email}!"
    )

    respond_with_success("✅ Успешно объединили аккаунты:\n📧 Email: #{@email}\n📱 Telegram: @#{@telegram_username}")
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

  def respond_with_error(text)
    @controller.respond_with :message, text: text
  end

  def respond_with_success(text)
    @controller.respond_with :message, text: text
  end
end

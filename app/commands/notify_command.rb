# frozen_string_literal: true

class NotifyCommand < BaseCommand
  NOTIFY_MESSAGE_INPUT = :notify_message_input
  MIN_MESSAGE_LENGTH = 3
  MAX_MESSAGE_LENGTH = 4000

  provides_context_methods :notify_message_input

  def call
    return respond_with :message, text: t('commands.notify.errors.access_denied') unless developer?

    save_context NOTIFY_MESSAGE_INPUT
    respond_with :message, text: t('commands.notify.prompts.enter_message')
  end

  def notify_message_input(message_text = '')
    return respond_with :message, text: t('commands.notify.errors.empty_message') if message.blank?
    return respond_with :message, text: t('commands.notify.errors.too_short') if message.length < MIN_MESSAGE_LENGTH
    return respond_with :message, text: t('commands.notify.errors.too_long') if message.length > MAX_MESSAGE_LENGTH
    return respond_with :message, text: t('commands.notify.cancelled') if message_text.downcase.strip == 'cancel'

    recipients = TelegramUser.all
    BroadcastNotificationJob.perform_later(message_text, recipients.map(&:id))
    respond_with :message, text: t('commands.notify.success', count: recipients.count)
  end
end

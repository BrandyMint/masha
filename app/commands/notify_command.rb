# frozen_string_literal: true

class NotifyCommand < BaseCommand
  MIN_MESSAGE_LENGTH = 3
  MAX_MESSAGE_LENGTH = 4000

  provides_context_methods NOTIFY_MESSAGE_INPUT

  def call
    return respond_with :message, text: t('commands.notify.errors.access_denied') unless developer?

    save_context NOTIFY_MESSAGE_INPUT
    respond_with :message, text: t('commands.notify.prompts.enter_message')
  end

  def notify_message_input(*args)
    message = args.join(' ')
    return respond_with :message, text: t('commands.notify.errors.empty_message') if message.blank?
    return respond_with :message, text: t('commands.notify.errors.too_short') if message.length < MIN_MESSAGE_LENGTH
    return respond_with :message, text: t('commands.notify.errors.too_long') if message.length > MAX_MESSAGE_LENGTH
    return respond_with :message, text: t('commands.notify.cancelled') if message.downcase.strip == 'cancel'

    BroadcastNotificationJob.perform_later(message)
    respond_with :message, text: t('commands.notify.success')
  end
end

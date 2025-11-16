# frozen_string_literal: true

class ResetCommand < BaseCommand
  command_metadata(hidden: true)

  def call(*_args)
    session.delete(:context)
    session.clear
    respond_with :message, text: t('telegram.commands.reset.success')
  end
end

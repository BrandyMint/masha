# frozen_string_literal: true

class TestCommand < BaseCommand
  command_metadata(developer_only: true)

  def call(*_args)
    respond_with :message, text: 'test passed'
    reply_with :message, text: 'Replied'
  end
end

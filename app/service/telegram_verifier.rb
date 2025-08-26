# frozen_string_literal: true

class TelegramVerifier
  include Singleton

  self.class.delegate :get_link, :parse, to: :instance

  def get_link(info)
    Rails.application.routes.url_helpers.attach_telegram_url verifier.generate(info)
  end

  def parse(token)
    verifier.verify token
  end

  private

  def verifier
    @verifier ||= ActiveSupport::MessageVerifier.new Rails.application.credentials.secret_key_base || 'fake_for_testing'
  end
end

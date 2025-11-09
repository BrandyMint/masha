# frozen_string_literal: true

module Commands
    class StartCommand < BaseCommand
      def call(word = nil, *_other_words)
        if word.to_s.start_with? TelegramHelper::AUTH_PREFIX
          handle_auth_start(word)
        elsif logged_in?
          respond_with :message, text: multiline('С возращением!', nil, nil, help_message)
        else
          respond_with :message,
                       text: "Привет! Чтобы авторизоваться перейдите на сайт: #{Rails.application.routes.url_helpers.new_session_url}"
        end
      end

      private

      def handle_auth_start(word)
        session_token = word.delete_prefix TelegramHelper::AUTH_PREFIX
        verifier = Rails.application.message_verifier :telegram
        data = { st: session_token, tid: telegram_user.id, t: Time.zone.now.to_i }
        token = verifier.generate(data, purpose: :login)
        respond_with :message,
                     text: "Вы авторизованы! Перейдите на сайт: #{Rails.application.routes.url_helpers.telegram_confirm_url(token:)}"
  end
end
end

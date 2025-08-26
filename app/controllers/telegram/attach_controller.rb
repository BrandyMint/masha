# frozen_string_literal: true

module Telegram
  class AttachController < ApplicationController
    before_action :require_login

    def create
      info = TelegramVerifier.parse params[:id]

      current_user.with_lock do
        current_user.authentications.where(provider: :telegram).delete_all
        current_user.authentications.create!(
          provider: :telegram,
          uid: info[:uid],
          auth_hash: { 'info' => info.stringify_keys }
        )
      end

      begin
        Telegram.bot.send_message chat_id: info[:uid],
                                  text: "Спасибо, теперь я знаю, что ты – #{current_user} на сайте. Дальше напиши /help"
      rescue Telegram::Bot::Forbidden
      end

      redirect_to profile_url, gflash: { notice: t('gflash.telegram_attached') }
    end
  end
end

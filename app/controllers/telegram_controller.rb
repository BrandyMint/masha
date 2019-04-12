class TelegramController < ApplicationController
  before_action :require_login

  def attach
    info = TelegramVerifier.parse params[:id]
    current_user.authentications.where(provider: :telegram).delete_all
    current_user.authentications.create!(
      provider: :telegram,
      uid: info[:uid],
      auth_hash: { 'info' => info.stringify_keys }
    )
    redirect_to profile_url, gflash: {notice: t('gflash.telegram_attached')}
  end
end

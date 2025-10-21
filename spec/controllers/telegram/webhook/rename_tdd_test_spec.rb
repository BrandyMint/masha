# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  describe '#rename! TDD test - should FAIL before fix' do
    include_context 'authenticated user'

    let!(:project) { create(:project, name: 'Old Project', slug: 'old-project') }
    let!(:membership) { create(:membership, user: user, project: project, role_cd: 0) } # owner role

    context 'when rename! is called in private chat' do
      include_context 'private chat'

      it 'should work because rename! requires personal chat but is missing from exceptions' do
        # Этот тест должен FAIL сейчас, потому что rename! требует личный чат
        # но отсутствует в списке исключений require_personal_chat
        #
        # Текущая ситуация:
        # - rename! в require_authenticated (OK)
        # - rename! НЕ в except: %i[attach! report! summary! add! projects! start! adduser!] (ПРОБЛЕМА!)
        #
        # Из-за этого require_personal_chat блокирует команду даже в приватном чате

        expect { dispatch_command :rename }.to respond_with_message(/Выберите проект для переименования/)
      end
    end
  end
end

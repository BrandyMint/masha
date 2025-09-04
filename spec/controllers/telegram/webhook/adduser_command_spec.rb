# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  describe '#adduser!' do
    include_context 'private chat'
    include_context 'authenticated user'

    let!(:project) { create(:project) }
    let!(:membership) { create(:membership, user: user, project: project, role_cd: 0) } # owner role

    context 'without parameters' do
      subject { -> { dispatch_command :adduser } }
      it { should respond_with_message(/Выберите проект, в который хотите добавить пользователя/) }
    end

    context 'without username' do
      subject { -> { dispatch_command :adduser, 'project1' } }
      it { should respond_with_message(/Укажите никнейм пользователя/) }
    end
  end
end

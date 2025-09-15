# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  describe '#users!' do
    include_context 'private chat'
    include_context 'authenticated user'

    let!(:other_user) { create(:user, :with_telegram) }
    let!(:project) { create(:project) }

    before do
      user.set_role(:owner, project)
    end

    context 'when user is developer' do
      before do
        allow(ApplicationConfig).to receive(:developer_telegram_id).and_return(from_id)
      end

      subject { -> { dispatch_command :users } }

      it 'responds with user list' do
        expect(subject).to respond_with_message(/Telegram не привязан|\*\*@/)
      end

      it 'includes project information' do
        expect(subject).to respond_with_message(/Проекты:/)
      end
    end

    context 'when user is not developer' do
      before do
        allow(ApplicationConfig).to receive(:developer_telegram_id).and_return(12_345)
      end

      subject { -> { dispatch_command :users } }

      it 'responds with access denied message' do
        expect(subject).to respond_with_message(/только разработчику системы/)
      end
    end
  end
end

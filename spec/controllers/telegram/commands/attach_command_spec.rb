# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::AttachCommand, type: :controller do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:project) { create(:project) }

  before do
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:find_project).and_return(project)
    allow(controller).to receive(:chat).and_return(chat_data)
  end

  describe '#call' do
    context 'when project_slug is blank' do
      let(:chat_data) { { 'id' => 123 } }

      it 'responds with instruction message' do
        command.call

        expect(controller).to have_received(:respond_with)
          .with(:message, text: 'Укажите первым аргументом проект, к которому присоединяете этот чат')
      end
    end

    context 'when chat is group chat (negative id)' do
      let(:chat_data) { { 'id' => -123 } }

      before do
        allow(project).to receive(:update)
        allow(project).to receive(:to_s).and_return('Test Project')
      end

      it 'attaches chat to project' do
        command.call('test_project')

        expect(project).to have_received(:update).with(telegram_chat_id: -123)
        expect(controller).to have_received(:respond_with)
          .with(:message, text: 'Установили этот чат основным в проекте Test Project')
      end
    end

    context 'when chat is personal chat (positive id)' do
      let(:chat_data) { { 'id' => 123 } }

      it 'responds with error message' do
        command.call('test_project')

        expect(controller).to have_received(:respond_with)
          .with(:message, text: 'Присоединять можно только чаты, личную переписку нельзя')
      end
    end
  end
end

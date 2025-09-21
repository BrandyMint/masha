# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::NewCommand, type: :controller do
  let(:controller) { instance_double(Telegram::WebhookController) }
  let(:command) { described_class.new(controller) }
  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:respond_with)
    allow(controller).to receive(:save_context)
  end

  describe '#call' do
    context 'when slug is not provided' do
      it 'asks for slug input' do
        command.call

        expect(controller).to have_received(:save_context).with(:new_project_slug_input)
        expect(controller).to have_received(:respond_with)
          .with(:message, text: 'Укажите slug (идентификатор) для нового проекта:')
      end
    end

    context 'when slug is provided' do
      let(:projects) { double('projects') }
      let(:project) { build(:project, slug: 'test_project') }

      before do
        allow(user).to receive(:projects).and_return(projects)
        allow(projects).to receive(:create!).and_return(project)
      end

      it 'creates new project' do
        command.call('test_project')

        expect(projects).to have_received(:create!).with(name: 'test_project', slug: 'test_project')
        expect(controller).to have_received(:respond_with)
          .with(:message, text: 'Создан проект `test_project`')
      end

      context 'when project creation fails' do
        let(:error) { ActiveRecord::RecordInvalid.new(project) }

        before do
          allow(projects).to receive(:create!).and_raise(error)
          allow(Bugsnag).to receive(:notify)
          allow(project).to receive_message_chain(:errors, :messages, :to_json).and_return('{"slug":["error"]}')
        end

        it 'handles creation error' do
          command.call('invalid_slug')

          expect(Bugsnag).to have_received(:notify).with(error)
          expect(controller).to have_received(:respond_with)
            .with(:message, text: 'Ошибка создания проекта {"slug":["error"]}')
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::NewCommand do
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
      it 'creates new project' do
        command.call('test_project')

        project = user.projects.find_by(slug: 'test_project')
        expect(project).to be_present
        expect(project.name).to eq('test_project')

        expect(controller).to have_received(:respond_with)
          .with(:message, text: 'Создан проект `test_project`')
      end

      context 'when project creation fails' do
        before do
          allow(Bugsnag).to receive(:notify)
          # Create a project with same slug to cause validation error
          create(:project, slug: 'duplicate_slug')
        end

        it 'handles creation error' do
          command.call('duplicate_slug')

          expect(Bugsnag).to have_received(:notify)
          expect(controller).to have_received(:respond_with)
            .with(:message, text: include('Ошибка создания проекта'))
        end
      end
    end
  end
end
